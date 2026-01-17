from typing import Any, Dict, Optional, Tuple


def capitalize_first_letter(value: Optional[str]) -> Optional[str]:
    """Retourne la meme chaine avec sa premiere lettre en majuscule / Returns the same string with its first letter uppercased."""
    if not isinstance(value, str) or not value:
        return value
    first_char = value[0]
    return f"{first_char.upper()}{value[1:]}"


def capitalize_class_names(payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    Force une majuscule sur chaque nom de classe et propage ce nom canonique aux metadonnees imbriquees / Enforces a leading capital letter for every class key and propagates the canonical name to nested metadata.
    """
    classes = payload.get("classes")
    if not isinstance(classes, dict):
        return payload

    renamed_classes: Dict[str, Any] = {}
    exact_mapping: Dict[str, str] = {}
    lower_mapping: Dict[str, str] = {}

    for original_name, class_payload in classes.items():
        if not isinstance(original_name, str):
            renamed_classes[original_name] = class_payload
            continue

        proposed_name = capitalize_first_letter(original_name) or original_name
        final_name = _deduplicate_name(proposed_name, renamed_classes)

        exact_mapping[original_name] = final_name
        lower_mapping.setdefault(original_name.lower(), final_name)

        renamed_classes[final_name] = class_payload
        _update_internal_class_name(class_payload, final_name)

    payload["classes"] = renamed_classes
    _propagate_relationship_names(payload, exact_mapping, lower_mapping)
    return payload


def _deduplicate_name(candidate: str, current: Dict[str, Any]) -> str:
    """Ajoute un suffixe numerique si besoin pour conserver l unicite des classes / Appends a numeric suffix when needed so that every class name stays unique."""
    final_name = candidate
    index = 2
    while final_name in current:
        final_name = f"{candidate}{index}"
        index += 1
    return final_name


def _update_internal_class_name(class_payload: Any, new_name: str) -> None:
    """Synchronise les champs `name` et `class_name` avec l identifiant resolu / Synchronises the `name` and `class_name` fields with the resolved identifier."""
    if not isinstance(class_payload, dict):
        return
    for key in ("name", "class_name"):
        value = class_payload.get(key)
        if isinstance(value, str) and value:
            class_payload[key] = capitalize_first_letter(value) or value


def _propagate_relationship_names(
    payload: Dict[str, Any],
    exact_mapping: Dict[str, str],
    lower_mapping: Dict[str, str],
) -> None:
    """Met a jour chaque relation selon la correspondance ancien vers nouveau nom / Updates every relationship entry according to the old to new mapping."""
    classes = payload.get("classes", {})
    if not isinstance(classes, dict):
        return

    for class_payload in classes.values():
        if not isinstance(class_payload, dict):
            continue
        relationships = class_payload.get("relationships", [])
        if not isinstance(relationships, list):
            continue
        for relation_entry in relationships:
            if not isinstance(relation_entry, dict):
                continue
            for relation_data in relation_entry.values():
                if not isinstance(relation_data, dict):
                    continue
                for key in ("source_name", "target_name"):
                    current_name = relation_data.get(key)
                    updated = _resolve_new_name(current_name, exact_mapping, lower_mapping)
                    if updated:
                        relation_data[key] = updated


def _resolve_new_name(
    name: Any,
    exact_mapping: Dict[str, str],
    lower_mapping: Dict[str, str],
) -> Optional[str]:
    """
    Recherche le nom canonique via les correspondances exactes ou insensibles a la casse sinon met simplement une majuscule / Finds the canonical name through exact or case insensitive mappings and falls back to capitalising the raw value.
    """
    if not isinstance(name, str) or not name:
        return None
    if name in exact_mapping:
        return exact_mapping[name]
    lowered = name.lower()
    if lowered in lower_mapping:
        return lower_mapping[lowered]
    return capitalize_first_letter(name)


__all__: Tuple[str, ...] = ("capitalize_class_names",)
