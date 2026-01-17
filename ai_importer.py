import argparse
import shutil
import zipfile
from pathlib import Path
from typing import Tuple


def next_backup_path(dst: Path) -> Path:
    """Return a non-conflicting backup path by appending _backup, _backup1, ... before suffix."""
    stem, suffix = dst.stem, dst.suffix
    parent = dst.parent
    candidate = parent / f"{stem}_backup{suffix}"
    idx = 1
    while candidate.exists():
        candidate = parent / f"{stem}_backup{idx}{suffix}"
        idx += 1
    return candidate


def copy_with_backup(src: Path, dst: Path, log_lines: list):
    """Copy src to dst, creating parent dirs; backup dst if it exists."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        backup = next_backup_path(dst)
        dst.rename(backup)
        log_lines.append(f"backup {dst} -> {backup}")
    shutil.copy2(src, dst)
    log_lines.append(f"copied {src} -> {dst}")


def import_zip(zip_path: Path, extract_dir: Path, project_root: Path, log_file: Path) -> None:
    if not zip_path.exists():
        raise FileNotFoundError(f"Zip introuvable: {zip_path}")

    # Reset extraction directory
    shutil.rmtree(extract_dir, ignore_errors=True)
    extract_dir.mkdir(parents=True, exist_ok=True)

    # Extract
    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(extract_dir)

    log_lines = [f"Import depuis {zip_path} vers {project_root}"]

    for src in extract_dir.rglob("*"):
        if src.is_dir():
            continue
        relative = src.relative_to(extract_dir)
        dst = project_root / relative
        copy_with_backup(src, dst, log_lines)

    log_file.parent.mkdir(parents=True, exist_ok=True)
    log_file.write_text("\n".join(log_lines), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Importe les fichiers générés par l'IA dans le GeneratedProject.")
    parser.add_argument(
        "--stack",
        choices=["spring", "fastapi", "laravel", "nestjs", "dart", "fiber"],
        required=True,
        help="Stack ciblée",
    )
    parser.add_argument("--zip", dest="zip_path", help="Chemin du zip à importer")
    parser.add_argument("--output", default="output", help="Répertoire de sortie utilisé par l'orchestrateur (contient GeneratedProject/)")
    parser.add_argument("--project-root", dest="project_root", help="Racine du projet généré (sinon <output>/GeneratedProject)")

    args = parser.parse_args()

    output_dir = Path(args.output)
    project_root = Path(args.project_root) if args.project_root else output_dir / "GeneratedProject"
    zip_path = Path(args.zip_path) if args.zip_path else output_dir / "ai_generated" / args.stack / "response.zip"
    extract_dir = output_dir / "ai_generated" / args.stack / "extracted"
    log_file = output_dir / "ai_generated" / args.stack / "import.log"

    import_zip(zip_path, extract_dir, project_root, log_file)
    print(f"Import terminé. Journal: {log_file}")


if __name__ == "__main__":
    main()
