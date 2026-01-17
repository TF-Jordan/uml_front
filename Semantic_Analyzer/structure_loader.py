import json
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Union

from Semantic_Analyzer.validators import SemanticValidator


def load_structure_parser_file(path: Union[str, Path]) -> Dict[str, Any]:
    """Charge un JSON structure_Parser et renvoie son contenu / Loads a structure_Parser JSON file and returns its content."""
    return json.loads(Path(path).read_text(encoding="utf-8"))


def normalize_structure_file(
    path: Union[str, Path],
    language: str = "java",
    known_types: Optional[Iterable[str]] = None,
) -> Dict[str, Any]:
    """
    Pipeline complet: charge le fichier puis normalise les types in place / Complete pipeline: loads the file then normalises every type in place.
    """
    payload = load_structure_parser_file(path)
    return normalize_structure_payload(payload, language=language, known_types=known_types)


def normalize_structure_payload(
    payload: Dict[str, Any],
    language: str = "java",
    known_types: Optional[Iterable[str]] = None,
    log: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Applique SemanticValidator sur `attribute_type`, `method_type` et `param_type` / Applies SemanticValidator to `attribute_type`, `method_type`, `param_type` fields across the structure.
    """
    validator = SemanticValidator(language=language)
    known = _collect_known_types(payload, known_types)
    cache: Dict[str, str] = {}

    def normalise(raw: Optional[str], context: str = "") -> Optional[str]:
        """Canonicalise une chaine de type en reutilisant un cache / Canonicalises a raw type string while leveraging a per run cache."""
        if raw is None:
            return None
        stripped = raw.strip()
        if not stripped:
            return raw
        cache_key = (language, stripped.lower())
        if cache_key in cache:
            return cache[cache_key]
        canonical = validator.normalize_type(stripped, known_types=known)
        cache[cache_key] = canonical
        if log is not None and canonical != raw:
            log.append(f"[type] {context} : '{raw}' -> '{canonical}'")
        return canonical

    for class_payload in payload.get("classes", {}).values():
        filtered_attributes = []
        for attribute in class_payload.get("attributes", []):
            _normalise_first_available(attribute, normalise, ("attribute_type", "type", "attributeType"), context_prefix=f"attribute {attribute.get('attribute_name')}")
            if _is_placeholder_attribute(attribute):
                if log is not None:
                    log.append(f"[filter] attribut placeholder ignoré: {attribute}")
                continue
            filtered_attributes.append(attribute)
        class_payload["attributes"] = filtered_attributes

        for method in class_payload.get("methods", []):
            if isinstance(method, dict) and "name" not in method and "method_name" in method:
                method["name"] = method.get("method_name")
            _normalise_first_available(method, normalise, ("method_type", "type", "return_type"), context_prefix=f"method {method.get('name') or method.get('method_name')}")

            params = method.get("parameters")
            if params is None:
                params = method.get("parameter")
            if not isinstance(params, list):
                continue

            for param in params:
                    _normalise_first_available(
                    param,
                    normalise,
                    ("param_type", "parameter_type", "type_param"),
                    context_prefix=f"param {param.get('param_name')}",
                )

    return payload


def _normalise_first_available(
    container: Dict[str, Any],
    normalise_func,
    keys: Iterable[str],
    context_prefix: str = "",
) -> None:
    """Applique la fonction de normalisation sur la premiere cle disponible / Applies the provided normaliser to the first matching key."""
    for key in keys:
        if key in container and isinstance(container[key], str):
            container[key] = normalise_func(container[key], f"{context_prefix} ({key})".strip())
            break


def _collect_known_types(
    payload: Dict[str, Any],
    extra_known: Optional[Iterable[str]],
) -> List[str]:
    """Assemble les types connus du payload et des indices externes / Aggregates known types from the payload and user provided hints."""
    known: List[str] = list(extra_known or [])
    for class_name, class_payload in payload.get("classes", {}).items():
        if class_name:
            known.append(class_name)
        candidate = class_payload.get("name") or class_payload.get("class_name")
        if candidate:
            known.append(candidate)
    return known

def _is_placeholder_attribute(attribute: Dict[str, Any]) -> bool:
    """Detecte et ignore les attributs vides issus du diagramme (ex: name: void)."""
    if not isinstance(attribute, dict):
        return False
    attr_name = (attribute.get("attribute_name") or attribute.get("name") or "").strip().lower()
    attr_type = (attribute.get("attribute_type") or attribute.get("type") or "").strip().lower()
    if attr_type == "void" and attr_name in {"name", "nom"}:
        return True
    return False


__all__ = [
    "load_structure_parser_file",
    "normalize_structure_file",
    "normalize_structure_payload",
]
