import argparse
from pathlib import Path
import sys
import os
import shutil

from CodeGenerator.DartGenerator import DartCodeGenerator
from CodeGenerator.FiberGenerator.fiber_code_generator import FiberCodeGenerator
from CodeGenerator.NestJSGenerator import NestJSCodeGenerator
# Import pipeline classes
from Lexer.lexer import Lexer
from Parser.parser import Parser
from Semantic_Analyzer.pipeline import run_pipeline
from CodeGenerator.SpringGenerator.spring_code_generator import SpringCodeGenerator
from CodeGenerator.FastApiGenerator.fastapi_code_generator import FastApiCodeGenerator
from CodeGenerator.LaravelGenerator.laravel_code_generator import LaravelCodeGenerator

# Prépare les imports du sequence_analyzer en ajoutant son dossier au sys.path
SEQ_ROOT = Path(__file__).resolve().parent / "TechnicalSequenceAnalyzer" / "sequence_analyzer"
seq_root_str = str(SEQ_ROOT)
if seq_root_str not in sys.path:
    sys.path.insert(0, seq_root_str)
import subprocess


def generate_class_project(
    class_diagram: Path,
    output_dir: Path,
    stack: str = "spring",
    project_name: str | None = None,
    config: dict | None = None,
) -> Path:
    """Prend un diagramme de classes draw.io et produit un projet bêta + JSON normalisé."""
    project_name = project_name or class_diagram.stem
    xml_content = class_diagram.read_text(encoding="utf-8")
    lexed = Lexer(xml_content).execute()
    parsed = Parser(lexed).execute()

    # Save raw parsed structure
    output_dir.mkdir(parents=True, exist_ok=True)
    raw_path = output_dir / "structure_Parser.json"
    raw_path.write_text(__import__("json").dumps(parsed, indent=2, ensure_ascii=False), encoding="utf-8")

    normalized = run_pipeline(raw_path, language="java", project_type=stack)
    norm_path = output_dir / f"{class_diagram.stem}_normalized.json"
    norm_path.write_text(__import__("json").dumps(normalized, indent=2, ensure_ascii=False), encoding="utf-8")

    stack_options = (config or {}).get(stack.lower(), {})

    if stack.lower() == "laravel":
       LaravelCodeGenerator(
           output_root=output_dir / "GeneratedProject",
           options=stack_options,
       ).generate_project(project_name, normalized)
    elif stack.lower() == "spring":
        SpringCodeGenerator(
            output_root=output_dir / "GeneratedProject",
            group_id=stack_options.get("group_id"),
            spring_boot_version=stack_options.get("spring_boot_version", "4.0.1"),
            java_version=stack_options.get("java_version", "21"),
            db=stack_options.get("db", "mysql"),
            dependencies=stack_options.get("dependencies", []),
            tests=stack_options.get("tests", "junit"),
        ).generate_project(project_name, normalized)
    elif stack.lower() == "dart":
        DartCodeGenerator(
            output_root=output_dir / "GeneratedProject",
            options=stack_options,
        ).generate_project(project_name, normalized)
    elif stack.lower() == "nestjs":
        NestJSCodeGenerator(
            output_root=output_dir / "GeneratedProject",
            options=stack_options,
        ).generate_project(project_name, normalized)
    elif stack.lower() == "fastapi":
        FastApiCodeGenerator(
            output_root=output_dir / "GeneratedProject",
            options=stack_options,
        ).generate_project(project_name, normalized)
    elif stack.lower() == "fiber":
        FiberCodeGenerator(
            output_root=output_dir / "GeneratedProject",
            options=stack_options,
        ).generate_project(project_name, normalized)
    else:
        raise ValueError("stack must be 'spring' or 'fastapi' or 'fiber' or 'laravel'")

    return norm_path


def main():
    parser = argparse.ArgumentParser(description="Orchestrateur : diagramme de classes -> projet bêta, puis diagramme de séquence -> prompt")
    parser.add_argument("class_diagram", type=Path, help="Fichier draw.io de classes")
    parser.add_argument(
        "--stack",
        choices=["spring", "fastapi", "laravel", "nestjs", "dart", "fiber"],
        default="spring",
        help="Stack cible",
    )
    parser.add_argument("--seq_diagram", type=Path, help="Fichier draw.io de séquence (optionnel)")
    parser.add_argument("--description", type=str, help="Description métier pour le prompt (optionnel)")
    parser.add_argument("--output", type=Path, default=Path("output"), help="Répertoire de sortie")
    parser.add_argument("--entities", type=Path, help="JSON d'entités normalisé (sinon celui généré) pour la phase séquence")
    parser.add_argument("--send-to-ai", action="store_true", help="Envoyer automatiquement le prompt/mapping à l'IA et importer la réponse")
    parser.add_argument("--ai-key", type=str, help="Clé API Claude (sinon ANTHROPIC_API_KEY)")
    parser.add_argument("--ai-model", type=str, default="claude-3-opus-20240229", help="Modèle Claude")

    args = parser.parse_args()

    # Nettoyer le répertoire de sortie avant de (re)générer
    if args.output.exists():
        if args.output.is_file():
            args.output.unlink()
        else:
            shutil.rmtree(args.output)

    # Phase 1 : classes -> projet bêta
    project_name = args.class_diagram.stem
    try:
        norm_path = generate_class_project(args.class_diagram, args.output, stack=args.stack)
        print(f"✅ Projet bêta généré dans {args.output}/GeneratedProject")
        print(f"✅ JSON normalisé : {norm_path}")
    except Exception as e:
        print(f"❌ Échec phase classes : {e}")
        sys.exit(1)

    # Phase 2 : séquence -> prompt (optionnel)
    if args.seq_diagram:
        seq_args = [
            sys.executable,
            str(SEQ_ROOT / "main.py"),
            str(args.seq_diagram),
            "--entities",
            str(args.entities or norm_path),
            "--output",
            str(args.output / "sequence_output"),
            "--stack",
            args.stack,
        ]
        if args.description:
            seq_args.extend(["--use-case", args.description])
        try:
            subprocess.run(seq_args, check=True)
            print(f"✅ Prompt généré dans {args.output / 'sequence_output'}")

            if args.send_to_ai:
                prompt_path = args.output / "sequence_output" / f"{args.seq_diagram.stem}_prompt.md"
                mapping_dir = args.output / "sequence_output"
                entities_path = Path(args.entities or norm_path)

                ai_cmd = [
                    sys.executable,
                    str(Path(__file__).parent / "ai_pipeline_claude.py"),
                    "--stack",
                    args.stack,
                    "--prompt-file",
                    str(prompt_path),
                    "--mapping-dir",
                    str(mapping_dir),
                "--entities-file",
                str(entities_path),
                "--output",
                str(args.output),
                "--model",
                args.ai_model,
                "--project-name",
                project_name,
            ]
            if args.ai_key:
                ai_cmd.extend(["--api-key", args.ai_key])
                try:
                    subprocess.run(ai_cmd, check=True)
                    print("✅ Réponse IA importée dans GeneratedProject")
                except subprocess.CalledProcessError as e:
                    print(f"⚠️ Envoi/Import IA échoué (exit {e.returncode})")
        except subprocess.CalledProcessError as e:
            print(f"⚠️ Phase séquence échouée (exit {e.returncode})")
        except Exception as e:
            print(f"⚠️ Phase séquence échouée : {e}")


if __name__ == "__main__":
    main()
