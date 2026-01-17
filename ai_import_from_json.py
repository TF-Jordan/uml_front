import argparse
import json
import shutil
from pathlib import Path
from typing import List, Dict, Any


def next_backup_path(dst: Path) -> Path:
    stem, suffix = dst.stem, dst.suffix
    parent = dst.parent
    candidate = parent / f"{stem}_backup{suffix}"
    idx = 1
    while candidate.exists():
        candidate = parent / f"{stem}_backup{idx}{suffix}"
        idx += 1
    return candidate


def copy_with_backup_text(content: str, dst: Path, log: List[str]) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        backup = next_backup_path(dst)
        dst.rename(backup)
        log.append(f"backup {dst} -> {backup}")
    dst.write_text(content, encoding="utf-8")
    log.append(f"written {dst}")


def import_from_json(json_path: Path, project_root: Path, log_path: Path) -> None:
    data = json.loads(json_path.read_text(encoding="utf-8"))
    files = data.get("files", [])
    if not isinstance(files, list):
        raise ValueError("Champ 'files' manquant ou invalide")

    log: List[str] = [f"Import JSON {json_path} vers {project_root}"]
    for entry in files:
        if not isinstance(entry, dict):
            continue
        rel_path = entry.get("path")
        content = entry.get("content")
        if not rel_path or content is None:
            continue
        dst = project_root / rel_path
        copy_with_backup_text(content, dst, log)

    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text("\n".join(log), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Importe des fichiers depuis un JSON {\"files\":[{\"path\":...,\"content\":...}]} dans GeneratedProject.")
    parser.add_argument("--json", required=True, help="Chemin du JSON fourni par l'IA.")
    parser.add_argument("--project-root", default="output/GeneratedProject", help="Racine du projet cible.")
    parser.add_argument("--log", default=None, help="Chemin du log (par défaut à côté du JSON).")
    args = parser.parse_args()

    json_path = Path(args.json)
    project_root = Path(args.project_root)
    log_path = Path(args.log) if args.log else json_path.with_suffix(".import.log")

    import_from_json(json_path, project_root, log_path)
    print(f"Import terminé. Journal: {log_path}")


if __name__ == "__main__":
    main()
