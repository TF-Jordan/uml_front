import json
from argparse import ArgumentParser
from pathlib import Path
from typing import Iterable, Optional, Union

if __package__ in (None, ""):
    import sys

    package_root = Path(__file__).resolve().parents[1]
    if str(package_root) not in sys.path:
        sys.path.append(str(package_root))

from Semantic_Analyzer.class_name_normalizer import capitalize_class_names
from Semantic_Analyzer.structure_loader import (
    load_structure_parser_file,
    normalize_structure_payload,
)
from Semantic_Analyzer.visibility_normalizer import normalize_visibility_payload
from Semantic_Analyzer.relationships_transformer import process_relationships


def run_pipeline(
    path: Union[str, Path],
    language: str = "java",
    known_types: Optional[Iterable[str]] = None,
    project_type: str = "spring",
):
    """
    Enchaine toutes les passes (visibilite, types, noms, relations) avant codegen /
    Chains all normalisation passes (visibility, types, names, relationships) before codegen.
    """
    data = load_structure_parser_file(path)
    data["project_type"] = project_type
    log: list[str] = []
    normalize_visibility_payload(data)
    normalize_structure_payload(data, language=language, known_types=known_types, log=log)
    capitalize_class_names(data)
    process_relationships(data, log=log)
    _write_log(log)
    return data


def main() -> None:  # pragma: no cover
    """Point d entree CLI pour lancer toute la pipeline sur un JSON / CLI entry point that runs the full pipeline on a JSON file."""
    parser = ArgumentParser(description="Pipeline complet : visibilité + types + relations.")
    parser.add_argument("path", type=Path, help="Chemin vers le fichier structure_Parser.json")
    parser.add_argument(
        "--language",
        default="java",
        choices=["java", "php", "python"],
        help="Langage cible pour la normalisation des types",
    )
    args = parser.parse_args()

    result = run_pipeline(args.path, language=args.language)
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()

def _write_log(log: list[str]) -> None:
    """Ecrit un log de normalisation dans un fichier texte."""
    if not log:
        return
    log_path = Path("/tmp/normalization_log.txt")
    content = "\n".join(log)

    try:
        log_path.write_text(content + "\n", encoding="utf-8")
    except:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        log_path.write_text(content + "\n", encoding="utf-8")
