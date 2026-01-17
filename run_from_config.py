import argparse
import shlex
import subprocess
from pathlib import Path
from datetime import datetime
import random
import string

from orchestrator import generate_class_project
from uml2code_config import (
    apply_defaults,
    load_config,
    prepare_output_dir,
    resolve_ai_key,
    resolve_path,
    validate_config,
)


def main() -> None:
    parser = argparse.ArgumentParser(description="Run UML2Code using a config JSON file.")
    parser.add_argument("config", help="Path to the config JSON file.")
    parser.add_argument("--validate", action="store_true", help="Validate config and exit.")
    args = parser.parse_args()

    config_path = Path(args.config)
    config = load_config(config_path)
    config = apply_defaults(config)
    errors = validate_config(config)
    if errors:
        print("Config validation failed:")
        for err in errors:
            print(f"- {err}")
        raise SystemExit(1)
    if args.validate:
        print("Config OK")
        return

    base_dir = config_path.parent
    meta = config.get("meta", {})
    inputs = config.get("inputs", {})
    pipeline = config.get("pipeline", {})
    ai = config.get("ai", {})

    stack = meta.get("stack")
    project_name = meta.get("project_name")

    output_dir = resolve_path(base_dir, meta.get("output_dir"))
    if output_dir is None:
        raise SystemExit("output_dir cannot be resolved")
    overwrite_strategy = pipeline.get("overwrite_strategy", "backup")
    output_dir = _resolve_scoped_output_dir(output_dir, project_name, overwrite_strategy)
    prepare_output_dir(output_dir, overwrite_strategy)

    class_diagram = resolve_path(base_dir, inputs.get("class_diagram_path"))
    if class_diagram is None or not class_diagram.exists():
        raise SystemExit(f"Class diagram not found: {class_diagram}")

    norm_path = generate_class_project(
        class_diagram,
        output_dir,
        stack=stack,
        project_name=project_name,
        config=config,
    )
    print(f"Generated project in {output_dir / 'GeneratedProject'}")
    print(f"Normalized JSON: {norm_path}")

    if pipeline.get("mode") != "class_plus_sequence_ia":
        return

    seq_diagram = resolve_path(base_dir, inputs.get("sequence_diagram_path"))
    if seq_diagram is None or not seq_diagram.exists():
        raise SystemExit(f"Sequence diagram not found: {seq_diagram}")

    seq_output = output_dir / "sequence_output"
    seq_args = [
        str(Path(__file__).parent / "TechnicalSequenceAnalyzer" / "sequence_analyzer" / "main.py"),
        str(seq_diagram),
        "--entities",
        str(norm_path),
        "--output",
        str(seq_output),
        "--stack",
        stack,
    ]
    _log_command("Sequence analyzer", [_python_executable(), *seq_args])
    subprocess.run([_python_executable(), *seq_args], check=True)
    print(f"Prompt generated in {seq_output}")

    if not ai.get("enabled"):
        return

    api_key = resolve_ai_key(ai)
    if not api_key:
        raise SystemExit("AI enabled but no API key found in environment")

    prompt_path = seq_output / f"{seq_diagram.stem}_prompt.md"
    mapping_dir = seq_output

    ai_cmd = [
        _python_executable(),
        str(Path(__file__).parent / "ai_pipeline_claude.py"),
        "--provider",
        ai.get("provider", "gemini"),
        "--stack",
        stack,
        "--prompt-file",
        str(prompt_path),
        "--mapping-dir",
        str(mapping_dir),
        "--entities-file",
        str(norm_path),
        "--output",
        str(output_dir),
        "--project-name",
        project_name,
        "--api-key",
        api_key,
    ]
    if ai.get("model"):
        ai_cmd.extend(["--model", str(ai.get("model"))])
    if ai.get("max_tokens"):
        ai_cmd.extend(["--max-tokens", str(ai.get("max_tokens"))])
    if ai.get("timeout_seconds"):
        ai_cmd.extend(["--timeout", str(ai.get("timeout_seconds"))])
    _log_command("AI pipeline", ai_cmd)
    try:
        subprocess.run(ai_cmd, check=True)
    except subprocess.CalledProcessError as exc:
        print(f"AI pipeline failed: {exc}")
        raise
    print("AI response imported into GeneratedProject")


def _python_executable() -> str:
    import sys

    return sys.executable


def _log_command(label: str, cmd: list[str]) -> None:
    formatted = shlex.join(str(part) for part in cmd)
    print(f"{label}: {formatted}")


def _resolve_scoped_output_dir(output_dir: Path, project_name: str | None, strategy: str) -> Path:
    if strategy != "backup":
        return output_dir
    if project_name:
        safe_name = _sanitize_name(project_name)
        if output_dir.name.startswith(f"{safe_name}_"):
            return output_dir
    output_dir.mkdir(parents=True, exist_ok=True)
    run_id = _build_run_id()
    safe_name = _sanitize_name(project_name or "projet")
    return output_dir / f"{safe_name}_{run_id}"


def _build_run_id() -> str:
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    suffix = "".join(random.choices(string.ascii_lowercase + string.digits, k=6))
    return f"{timestamp}_{suffix}"


def _sanitize_name(value: str) -> str:
    cleaned = []
    for ch in value.strip():
        if ch.isalnum() or ch in {"-", "_"}:
            cleaned.append(ch)
        elif ch.isspace():
            cleaned.append("_")
    return "".join(cleaned) or "projet"


if __name__ == "__main__":
    main()
