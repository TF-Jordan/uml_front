import json
from argparse import ArgumentParser
from pathlib import Path
from typing import Any, Dict, Iterable, Union

VISIBILITY_MAP = {
    "+": "public",
    "-": "private",
    "#": "protected",
    "~": "package-private",
}


def normalize_visibility_value(value: Any) -> Any:
    """Convertit les visibilites UML en mots cles explicites / Converts UML style visibility markers into explicit keywords."""
    if not isinstance(value, str):
        return value
    stripped = value.strip()
    if not stripped:
        return value

    lowered = stripped.lower()
    if lowered in VISIBILITY_MAP.values():
        return lowered

    return VISIBILITY_MAP.get(stripped, stripped)


def normalize_visibility_payload(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Parcourt chaque classe attribut methode pour normaliser la visibilite / Walks through each class attribute method to normalise the visibility flag."""
    for class_payload in payload.get("classes", {}).values():
        if not isinstance(class_payload, dict):
            continue

        for attribute in class_payload.get("attributes", []):
            attribute["visibility"] = normalize_visibility_value(attribute.get("visibility"))

        for method in class_payload.get("methods", []):
            method["visibility"] = normalize_visibility_value(method.get("visibility"))

    return payload


def normalize_visibility_file(path: Union[str, Path]) -> Dict[str, Any]:
    """Charge puis normalise un fichier JSON en une seule passe / Loads then normalises a JSON file in one pass."""
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    return normalize_visibility_payload(data)


def main() -> None:  # pragma: no cover
    """Petit outil CLI pour lancer le normaliseur depuis le terminal / Small CLI helper to invoke the normaliser from the terminal."""
    parser = ArgumentParser(description="Remplace les symboles de visibilité (+, -, #, ~) par des mots-clés.")
    parser.add_argument("path", type=Path, help="Chemin vers le JSON structure_Parser.")
    args = parser.parse_args()

    normalized = normalize_visibility_file(args.path)
    print(json.dumps(normalized, indent=2, ensure_ascii=False))


if __name__ == "__main__":  # pragma: no cover
    main()
