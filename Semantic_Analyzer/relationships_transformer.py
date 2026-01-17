import json
from argparse import ArgumentParser
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple, Union

from Semantic_Analyzer.class_name_normalizer import capitalize_class_names


def normalize_key(value: Optional[str]) -> Optional[str]:
    """Standardise les identifiants en snake_case minuscule / Standardises identifiers to lower snake_case."""
    if not isinstance(value, str):
        return value
    return value.strip().lower().replace(" ", "_")

def build_attribute(name: str, type_name: str, visibility: str = "private") -> Dict[str, Any]:
    """Cree un attribut reutilisable lors de la transformation des relations / Produces the attribute payload reused when relationships add structural fields."""
    return {
        "visibility": visibility,
        "attribute_name": name,
        "attribute_type": type_name,
    }


def is_many(cardinality: Optional[str]) -> bool:
    """Renvoie True si la cardinalite UML represente une collection / Returns True when the UML cardinality denotes a collection."""
    if not isinstance(cardinality, str):
        return False
    normalized = cardinality.strip().lower()
    if not normalized:
        return False
    if "*" in normalized or "n" in normalized:
        return True
    if normalized.endswith("..*"):
        return True
    return normalized in {"*", "n"}


def is_single(cardinality: Optional[str]) -> bool:
    """Renvoie True pour les cardinalites 0..1 ou 1..1 / Returns True when the relationship is single valued."""
    return not is_many(cardinality)

def _normalize_relationship_entry(
    raw: Any,
    index_hint: int,
) -> Iterable[Tuple[str, Dict[str, Any]]]:
    """
    Accepte l ancien format plat produit par le parseur et le format imbrique attendu /
    Accepts both the legacy flat parser format and the expected nested format.
    """
    if not isinstance(raw, dict):
        return []

    # Format attendu: {"relation_id": {...}}
    if len(raw) == 1:
        key, value = next(iter(raw.items()))
        if isinstance(value, dict):
            return [(key, value)]

    # Format legacy: {name: "...", type: "...", source_name: "...", ...}
    return [(f"relation_{index_hint}", raw)]

def _build_association_label(
    association_name: str,
    relation_id: Optional[str],
    source_name: Optional[str],
) -> str:
    """
    Retourne un libelle exploitable pour nommer un attribut genere par une relation /
    Returns a usable label to name an attribute generated from a relationship.
    """
    if association_name and not association_name.isdigit():
        return association_name
    if source_name:
        return source_name
    if relation_id:
        return relation_id
    return ""


def process_relationships(payload: Dict[str, Any], log: Optional[List[str]] = None) -> Dict[str, Any]:
    """
    Convertit la liste brute des relations en clauses extends, implements et attributs / Converts the loose relationship list into extends, implements and attribute-level associations.
    """
    capitalize_class_names(payload)
    classes: Dict[str, Dict[str, Any]] = payload.get("classes", {})
    index: Dict[str, Tuple[Dict[str, Any], str]] = {}
    for name, class_payload in list(classes.items()):
        if not isinstance(class_payload, dict):
            continue
        index[normalize_key(name)] = (class_payload, name)

    seen_global: set = set()

    for class_name, class_payload in list(classes.items()):
        if not isinstance(class_payload, dict):
            continue

        relationships = class_payload.pop("relationships", [])
        if not isinstance(relationships, list):
            continue

        for idx, relationship_entry in enumerate(relationships):
            for relation_id, relation_data in _normalize_relationship_entry(relationship_entry, idx):
                if not isinstance(relation_data, dict):
                    continue

                relation_type = (relation_data.get("type", "") or "").strip().lower()
                if relation_type == "agregation":
                    relation_type = "aggregation"
                source_name = relation_data.get("source_name")
                target_name = relation_data.get("target_name")
                association_name = relation_data.get("name") or ""
                attribute_label = _build_association_label(
                    association_name,
                    relation_id,
                    source_name,
                )
                if relation_type == "association":
                    if "$" in association_name or "$" in attribute_label:
                        relation_type = "composition"
                        association_name = _strip_relation_hint(association_name)
                        attribute_label = _strip_relation_hint(attribute_label)
                    elif "#" in association_name or "#" in attribute_label:
                        relation_type = "aggregation"
                        association_name = _strip_relation_hint(association_name)
                        attribute_label = _strip_relation_hint(attribute_label)

                dedupe_key = (
                    relation_type,
                    normalize_key(source_name),
                    normalize_key(target_name),
                    association_name,
                    (relation_data.get("source_cardinality") or "").strip(),
                    (relation_data.get("target_cardinality") or "").strip(),
                )
                if dedupe_key in seen_global:
                    continue
                seen_global.add(dedupe_key)

                normalized_source = normalize_key(source_name)
                normalized_target = normalize_key(target_name)

                source_entry = index.get(normalized_source)
                target_entry = index.get(normalized_target)

                if source_entry is None or target_entry is None:
                    if log is not None:
                        log.append(f"[relation ignored] {relation_type} {source_name}->{target_name} (classe manquante)")
                    continue

                source_class, source_real_name = source_entry
                target_class, target_real_name = target_entry

                if relation_type in {"inheritance", "extends"}:
                    append_inheritance(
                        source_class,
                        target_class,
                        target_real_name,
                        source_real_name,
                        log,
                    )
                elif relation_type in {"implementation", "implements"}:
                    append_implementation(source_class, target_class, target_real_name, log)
                else:
                    append_other_relationship(
                        relation_type,
                        source_class,
                        target_class,
                        source_real_name,
                        target_real_name,
                        attribute_label,
                        relation_data.get("source_cardinality"),
                        relation_data.get("target_cardinality"),
                        classes,
                        index,
                        log,
                    )

    return payload

def append_inheritance(
    source_class: Dict[str, Any],
    parent_class: Dict[str, Any],
    parent_name: Optional[str],
    source_name: Optional[str] = None,
    log: Optional[List[str]] = None,
) -> None:
    """Ajoute une clause extends en imposant l heritage unique / Attaches an extends clause while enforcing single inheritance."""
    if not parent_name:
        return
    type_value = source_class.get("type", "") or ""
    type_str = type_value if isinstance(type_value, str) else str(type_value)
    existing_parent: Optional[str] = None
    if "extends" in type_str:
        # Extrait le parent déjà défini pour éviter les doublons / Extract existing parent to avoid duplicates.
        existing_parent = type_str.split("extends", 1)[1].split(",", 1)[0].strip()
    if existing_parent:
        if existing_parent.lower() == parent_name.lower():
            if log is not None:
                log.append(
                    f"[extends skipped] {source_name or source_class.get('name')} -> {parent_name} (déjà défini)"
                )
            return
        # Enforce single inheritance but keep le premier extends sans planter / keep first extends and skip extras.
        if log is not None:
            log.append(
                f"[extends ignored] {source_name or source_class.get('name')} -> {parent_name} (déjà {existing_parent})"
            )
        return
    clause = f", extends {parent_name}"
    source_class["type"] = f"{type_str}{clause}".strip(", ")
    if log is not None:
        log.append(f"[extends] {source_name or source_class.get('name')} -> {parent_name}")

def append_implementation(
    source_class: Dict[str, Any],
    interface_class: Dict[str, Any],
    interface_name: Optional[str],
    log: Optional[List[str]] = None,
) -> None:
    """Ajoute une clause implements et clone les methodes d interface / Appends an implements clause and clones interface methods into the class."""
    if not interface_name:
        return
    type_value = source_class.get("type", "") or ""
    type_str = type_value if isinstance(type_value, str) else str(type_value)
    base_part = type_str
    existing_interfaces: List[str] = []
    if "implements" in type_str:
        base_part, implements_part = type_str.split("implements", 1)
        existing_interfaces = [chunk.strip() for chunk in implements_part.split(",") if chunk.strip()]
    existing_lower = {iface.lower() for iface in existing_interfaces}
    if interface_name.lower() in existing_lower:
        if log is not None:
            log.append(
                f"[implements skipped] {source_class.get('name')} -> {interface_name} (déjà défini)"
            )
        return
    all_interfaces = existing_interfaces + [interface_name]
    base_part = base_part.strip().strip(",")
    prefix = f"{base_part}, " if base_part else ""
    source_class["type"] = f"{prefix}implements {', '.join(all_interfaces)}".strip(", ")
    interface_methods = interface_class.get("methods", [])
    existing_names = {method.get("name") for method in source_class.get("methods", [])}
    for method in interface_methods:
        method_name = method.get("name")
        if method_name in existing_names:
            continue
        source_class.setdefault("methods", []).append(json.loads(json.dumps(method)))
    if log is not None:
        log.append(f"[implements] {source_class.get('name')} -> {interface_name}")

def append_other_relationship(
    relation_type: str,
    source_class: Dict[str, Any],
    target_class: Dict[str, Any],
    source_name: Optional[str],
    target_name: Optional[str],
    association_name: str,
    source_cardinality: Optional[str],
    target_cardinality: Optional[str],
    classes: Dict[str, Dict[str, Any]],
    index: Dict[str, Tuple[Dict[str, Any], str]],
    log: Optional[List[str]] = None,
) -> None:
    """Traite associations, aggregations, compositions et cas speciaux / Handles association, aggregation, composition and fallback cases."""
    if relation_type in {"aggregation", "composition"}:
        if not source_name or not target_name:
            return
        attribute_name = _strip_relation_hint(association_name or source_name)
        target_class.setdefault("attributes", []).append(
            build_attribute(attribute_name, source_name)
        )
        if log is not None:
            log.append(f"[{relation_type}] {target_name} <- {attribute_name}:{source_name}")
        return

    if relation_type == "association":
        source_many = is_many(source_cardinality)
        target_many = is_many(target_cardinality)
        if source_many and target_many:
            append_join_table(classes, index, source_name, target_name, association_name, log)
        elif is_single(source_cardinality):
            if not source_name:
                return
            attribute_name = association_name or source_name
            target_class.setdefault("attributes", []).append(
                build_attribute(attribute_name, source_name)
            )
            if log is not None:
                log.append(f"[association] {target_name} <- {attribute_name}:{source_name} (1..1)")

def append_join_table(
    classes: Dict[str, Dict[str, Any]],
    index: Dict[str, Tuple[Dict[str, Any], str]],
    source_name: Optional[str],
    target_name: Optional[str],
    association_name: str,
    log: Optional[List[str]] = None,
) -> None:
    """Cree une classe de jointure implicite pour les associations plusieurs a plusieurs / Creates an implicit join class when a many-to-many association is detected."""
    if not source_name or not target_name:
        return
    class_key = f"{source_name}_{association_name}_{target_name}"
    if class_key in classes:
        return
    join_class = {
        "type": "classe",
        "attributes": [
            build_attribute(f"{source_name}_ref", source_name),
            build_attribute(f"{target_name}_ref", target_name),
        ],
        "methods": [],
    }
    classes[class_key] = join_class
    index[normalize_key(class_key)] = (join_class, class_key)
    if log is not None:
        log.append(f"[association many-to-many] join class {class_key} for {source_name}<->{target_name}")

def _strip_relation_hint(label: str) -> str:
    """Retire les indicateurs $/# des labels de relation."""
    if not isinstance(label, str):
        return label
    return label.replace("$", "").replace("#", "")

def transform_relationships_file(path: Union[str, Path]) -> Dict[str, Any]:
    """Charge un JSON puis applique process_relationships / Loads a JSON file then runs `process_relationships`."""
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    return process_relationships(data)

def main() -> None:
    """Point d entree CLI pour transformer uniquement les relations / CLI entry point dedicated to relationships."""
    parser = ArgumentParser(description="Transforme les relations selon les règles spécifiées.")
    parser.add_argument("path", type=Path, help="Chemin vers le JSON structure_Parser.")
    args = parser.parse_args()

    transformed = transform_relationships_file(args.path)
    print(json.dumps(transformed, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    main()
