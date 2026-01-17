import json
from argparse import ArgumentParser
from pathlib import Path
from typing import Iterable, Optional, Union

from Lexer.lexer import Lexer
from Parser.parser import Parser
from helpers.utils import Utils

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
from CodeGenerator.SpringGenerator.spring_code_generator import SpringCodeGenerator
from CodeGenerator.FastApiGenerator.fastapi_code_generator import FastApiCodeGenerator


def run_parser():

    # Chargement du fichier
    diagram = Path("datas/diagramTest.drawio")
    xml_content = diagram.read_text("utf-8")

    # print("1")
    # Creation du lexer
    lexer = Lexer(xml_content)

    # print("2")
    # Execution
    token = lexer.execute()

    # print ("bonjour")
    parser = Parser(token)

    # print ("bonjour")
    result = parser.execute()
    return result

    # Utils.dump("../Parser/result_parser.json", result)

def run_pipeline(project_name: str, project_type: str = "fastapi"):
    """
    Enchaine toutes les passes (visibilite, types, noms, relations) avant codegen /
    Chains all normalisation passes (visibility, types, names, relationships) before codegen.
    """
    # data = load_structure_parser_file(path)
    data = run_parser()

    with open("debug_output1.json", "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    normalize_visibility_payload(data)
    target_language = "java" if project_type.lower() == "spring" else "python"
    normalize_structure_payload(data, language=target_language, known_types=None)
    capitalize_class_names(data)
    data["project_type"] = project_type
    process_relationships(data)
    result =  {project_name: data}
    return result


def generate_project(project_name: str, project_type: str = "spring") -> None:
    """
    Fonction publique qui prend simplement le nom du projet et déclenche la génération demandée.
    """
    # Le project_type est utilisé pour ajuster le langage de normalisation et annoter le payload
    project_payload = run_pipeline(project_name, project_type=project_type)

    with open("debug_output.json", "w", encoding="utf-8") as f:
        json.dump(project_payload, f, indent=2, ensure_ascii=False)

    payload = project_payload[project_name]
    if project_type.lower() == "fastapi":
        generator = FastApiCodeGenerator()
        generator.generate_project(project_name, payload)
    else:
        generator = SpringCodeGenerator()
        generator.generate_project(project_name, payload)


def main() -> None:  # pragma: no cover
    """Point d entree CLI pour lancer toute la pipeline sur un JSON / CLI entry point that runs the full pipeline on a JSON file."""
    parser = ArgumentParser(description="Pipeline complet : visibilité + types + relations + génération.")
    parser.add_argument("--project-name", default="Testproject", help="Nom du projet généré")
    parser.add_argument(
        "--project-type",
        default="fastapi",
        choices=["spring", "fastapi"],
        help="Type de projet à générer",
    )
    args = parser.parse_args()

    generate_project(args.project_name, project_type=args.project_type)


if __name__ == "__main__":
    main()
