import os
import subprocess
import sys
import zipfile
from pathlib import Path
from typing import Optional

from api_server.storage import (
    LOG_FILE,
    NORMALIZED_JSON,
    RESULT_ZIP,
    update_status,
)


def run_job(job_id: str, config_path: str, job_dir: str, ai_api_key: Optional[str] = None) -> None:
    job_root = Path(job_dir)
    log_path = job_root / LOG_FILE
    update_status(job_root, state="running", started_at=_now_iso())

    env = os.environ.copy()
    if ai_api_key:
        env["UML2CODE_AI_KEY"] = ai_api_key

    command = [sys.executable, str(_project_root() / "run_from_config.py"), str(config_path)]

    with log_path.open("a", encoding="utf-8") as log_file:
        process = subprocess.run(
            command,
            cwd=_project_root(),
            stdout=log_file,
            stderr=log_file,
            env=env,
        )

    if process.returncode != 0:
        update_status(
            job_root,
            state="failed",
            finished_at=_now_iso(),
            error=f"run_from_config exited with code {process.returncode}",
        )
        return

    output_dir = job_root / "output"
    project_dir = output_dir / "GeneratedProject"
    zip_path = job_root / RESULT_ZIP
    if project_dir.exists():
        _create_zip(project_dir, zip_path)

    normalized_src = _find_normalized(output_dir)
    normalized_dst = job_root / NORMALIZED_JSON
    if normalized_src:
        normalized_dst.write_text(normalized_src.read_text(encoding="utf-8"), encoding="utf-8")

    update_status(
        job_root,
        state="finished",
        finished_at=_now_iso(),
        result_zip=str(zip_path.name) if zip_path.exists() else None,
        normalized_json=str(normalized_dst.name) if normalized_dst.exists() else None,
    )


def _project_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _create_zip(source_dir: Path, zip_path: Path) -> None:
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zipf:
        for file in source_dir.rglob("*"):
            if file.is_file():
                zipf.write(file, file.relative_to(source_dir))


def _find_normalized(output_dir: Path) -> Optional[Path]:
    candidates = list(output_dir.glob("*_normalized.json"))
    if not candidates:
        return None
    return candidates[0]


def _now_iso() -> str:
    from datetime import datetime, timezone

    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
