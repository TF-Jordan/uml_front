import json
import sys
from argparse import ArgumentParser
from pathlib import Path

# Allow execution via `python semantic_analyser_v2/run_validator.py ...`
if __package__ is None or __package__ == "":
    sys.path.append(str(Path(__file__).resolve().parents[1]))

from Semantic_Analyzer.structure_loader import normalize_structure_file


def main() -> None:
    """Outil CLI pour exposer SemanticValidator seul / CLI helper exposing SemanticValidator without the full pipeline."""
    parser = ArgumentParser(description="Normalise un fichier structure_Parser.json via SemanticValidator v2.")
    parser.add_argument(
        "path",
        type=Path,
        help="../debug_output.json",
    )
    parser.add_argument(
        "--language",
        default="java",
        choices=["java", "php", "python"],
        help="Langage cible pour la normalisation (default: java).",
    )
    args = parser.parse_args()

    normalized = normalize_structure_file(
        args.path,
        language=args.language,
        known_types=None,
    )
    print(json.dumps(normalized, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
