import json
import shutil
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple

from api_server.settings import DEFAULT_RETAIN_DAYS, JOB_STORE

STATUS_FILE = "status.json"
LOG_FILE = "logs.txt"
CONFIG_FILE = "config.json"
RESULT_ZIP = "result.zip"
NORMALIZED_JSON = "normalized.json"


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def isoformat(value: datetime) -> str:
    return value.isoformat().replace("+00:00", "Z")


def create_job_dir(base_dir: Path | None = None) -> Tuple[str, Path]:
    root = base_dir or JOB_STORE
    root.mkdir(parents=True, exist_ok=True)
    job_id = uuid.uuid4().hex
    job_dir = root / job_id
    (job_dir / "input").mkdir(parents=True, exist_ok=False)
    (job_dir / "output").mkdir(parents=True, exist_ok=True)
    return job_id, job_dir


def write_status(job_dir: Path, status: Dict[str, Any]) -> None:
    status_path = job_dir / STATUS_FILE
    status_path.write_text(json.dumps(status, indent=2), encoding="utf-8")


def read_status(job_dir: Path) -> Dict[str, Any]:
    status_path = job_dir / STATUS_FILE
    if not status_path.exists():
        return {}
    return json.loads(status_path.read_text(encoding="utf-8"))


def update_status(job_dir: Path, **fields: Any) -> Dict[str, Any]:
    status = read_status(job_dir)
    status.update(fields)
    status["updated_at"] = isoformat(utc_now())
    write_status(job_dir, status)
    return status


def build_initial_status(
    job_id: str,
    project_name: str,
    stack: str,
    retain_days: Optional[int] = None,
) -> Dict[str, Any]:
    now = utc_now()
    keep_days = retain_days if retain_days is not None else DEFAULT_RETAIN_DAYS
    expires_at = now + timedelta(days=keep_days)
    return {
        "job_id": job_id,
        "project_name": project_name,
        "stack": stack,
        "state": "queued",
        "created_at": isoformat(now),
        "updated_at": isoformat(now),
        "retain_days": keep_days,
        "expires_at": isoformat(expires_at),
        "error": None,
        "result_zip": None,
        "normalized_json": None,
    }


def list_jobs(base_dir: Path | None = None) -> List[Dict[str, Any]]:
    root = base_dir or JOB_STORE
    if not root.exists():
        return []
    statuses: List[Dict[str, Any]] = []
    for entry in root.iterdir():
        if not entry.is_dir():
            continue
        status = read_status(entry)
        if status:
            statuses.append(status)
    return statuses


def is_expired(status: Dict[str, Any], now: Optional[datetime] = None) -> bool:
    if not status:
        return False
    expires_at = status.get("expires_at")
    if not expires_at:
        return False
    current = now or utc_now()
    try:
        expiry = datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
    except ValueError:
        return False
    return current >= expiry


def cleanup_expired_jobs(base_dir: Path | None = None) -> int:
    root = base_dir or JOB_STORE
    if not root.exists():
        return 0
    removed = 0
    now = utc_now()
    for entry in root.iterdir():
        if not entry.is_dir():
            continue
        status = read_status(entry)
        if is_expired(status, now=now):
            shutil.rmtree(entry, ignore_errors=True)
            removed += 1
    return removed


def job_dir_from_id(job_id: str, base_dir: Path | None = None) -> Path:
    root = base_dir or JOB_STORE
    return root / job_id
