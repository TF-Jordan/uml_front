import json
import shutil
from pathlib import Path
from typing import Any, Dict, Optional

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import FileResponse

from api_server.jobs import run_job
from api_server.queue import get_queue
from api_server.storage import (
    CONFIG_FILE,
    LOG_FILE,
    NORMALIZED_JSON,
    RESULT_ZIP,
    build_initial_status,
    cleanup_expired_jobs,
    create_job_dir,
    job_dir_from_id,
    read_status,
    update_status,
    write_status,
)
from uml2code_config import apply_defaults, validate_config


app = FastAPI(title="UML2Code API", version="1.0.0")


async def _save_upload(file: UploadFile, destination: Path) -> None:
    content = await file.read()
    destination.write_bytes(content)


def _parse_config(config_text: Optional[str]) -> Dict[str, Any]:
    if not config_text:
        return {}
    try:
        data = json.loads(config_text)
    except json.JSONDecodeError as exc:
        raise HTTPException(400, f"Invalid config JSON: {exc}") from exc
    if not isinstance(data, dict):
        raise HTTPException(400, "Config must be a JSON object")
    return data


def _merge_if_not_none(container: Dict[str, Any], key: str, value: Any) -> None:
    if value is not None:
        container[key] = value


@app.post("/jobs")
async def create_job(
    class_diagram: UploadFile = File(...),
    sequence_diagram: Optional[UploadFile] = File(None),
    config: Optional[str] = Form(None),
    project_name: Optional[str] = Form(None),
    stack: Optional[str] = Form(None),
    mode: Optional[str] = Form(None),
    ai_enabled: Optional[bool] = Form(None),
    ai_provider: Optional[str] = Form(None),
    ai_model: Optional[str] = Form(None),
    ai_api_key: Optional[str] = Form(None),
):
    cleanup_expired_jobs()

    job_id, job_dir = create_job_dir()
    input_dir = job_dir / "input"

    class_suffix = Path(class_diagram.filename or "class.drawio").suffix or ".drawio"
    class_path = input_dir / f"class_diagram{class_suffix}"
    await _save_upload(class_diagram, class_path)

    seq_path = None
    if sequence_diagram:
        seq_suffix = Path(sequence_diagram.filename or "sequence.drawio").suffix or ".drawio"
        seq_path = input_dir / f"sequence_diagram{seq_suffix}"
        await _save_upload(sequence_diagram, seq_path)

    config_data = _parse_config(config)
    meta = config_data.setdefault("meta", {})
    inputs = config_data.setdefault("inputs", {})
    pipeline = config_data.setdefault("pipeline", {})
    ai = config_data.setdefault("ai", {})

    _merge_if_not_none(meta, "project_name", project_name)
    _merge_if_not_none(meta, "stack", stack)
    _merge_if_not_none(pipeline, "mode", mode)

    if ai_enabled is not None:
        ai["enabled"] = ai_enabled
    _merge_if_not_none(ai, "provider", ai_provider)
    _merge_if_not_none(ai, "model", ai_model)

    if ai_api_key:
        ai["enabled"] = True
        ai["user_key_id"] = "UML2CODE_AI_KEY"

    inputs["class_diagram_path"] = str(Path("input") / class_path.name)
    if seq_path:
        inputs["sequence_diagram_path"] = str(Path("input") / seq_path.name)

    meta.setdefault("project_name", Path(class_diagram.filename or "project").stem)
    meta.setdefault("stack", "spring")
    meta["output_dir"] = "output"

    pipeline.setdefault("mode", "class_only")
    pipeline.setdefault("overwrite_strategy", "overwrite")

    config_data = apply_defaults(config_data)
    errors = validate_config(config_data)
    if errors:
        shutil.rmtree(job_dir, ignore_errors=True)
        raise HTTPException(422, {"errors": errors})

    config_path = job_dir / CONFIG_FILE
    config_path.write_text(json.dumps(config_data, indent=2), encoding="utf-8")

    status = build_initial_status(
        job_id,
        project_name=meta.get("project_name", job_id),
        stack=meta.get("stack", "unknown"),
        retain_days=config_data.get("pipeline", {}).get("retain_days"),
    )
    write_status(job_dir, status)

    queue = get_queue()
    queue.enqueue(
        run_job,
        job_id,
        str(config_path),
        str(job_dir),
        ai_api_key=ai_api_key,
        job_id=job_id,
    )

    return {
        "job_id": job_id,
        "state": "queued",
        "status_url": f"/jobs/{job_id}",
        "logs_url": f"/jobs/{job_id}/logs",
        "result_url": f"/jobs/{job_id}/result.zip",
    }


@app.get("/jobs")
def list_jobs():
    cleanup_expired_jobs()
    return {"jobs": read_all_statuses()}


@app.get("/jobs/{job_id}")
def get_job(job_id: str):
    job_dir = job_dir_from_id(job_id)
    if not job_dir.exists():
        raise HTTPException(404, "Job not found")
    return read_status(job_dir)


@app.get("/jobs/{job_id}/logs")
def get_logs(job_id: str, offset: int = 0, limit: int = 65536):
    job_dir = job_dir_from_id(job_id)
    if not job_dir.exists():
        raise HTTPException(404, "Job not found")
    log_path = job_dir / LOG_FILE
    if not log_path.exists():
        return {"content": "", "next_offset": offset, "done": False}

    with log_path.open("rb") as handle:
        handle.seek(offset)
        data = handle.read(limit)
        next_offset = offset + len(data)
        content = data.decode("utf-8", errors="replace")

    status = read_status(job_dir)
    done = status.get("state") in {"finished", "failed", "canceled"}
    file_size = log_path.stat().st_size
    return {
        "content": content,
        "next_offset": next_offset,
        "done": done and next_offset >= file_size,
    }


@app.get("/jobs/{job_id}/result.zip")
def download_result(job_id: str):
    job_dir = job_dir_from_id(job_id)
    if not job_dir.exists():
        raise HTTPException(404, "Job not found")
    zip_path = job_dir / RESULT_ZIP
    if not zip_path.exists():
        raise HTTPException(404, "Result not ready")
    return FileResponse(zip_path)


@app.get("/jobs/{job_id}/normalized.json")
def download_normalized(job_id: str):
    job_dir = job_dir_from_id(job_id)
    if not job_dir.exists():
        raise HTTPException(404, "Job not found")
    normalized_path = job_dir / NORMALIZED_JSON
    if not normalized_path.exists():
        raise HTTPException(404, "Normalized JSON not ready")
    return FileResponse(normalized_path)


@app.post("/jobs/{job_id}/cancel")
def cancel_job(job_id: str):
    job_dir = job_dir_from_id(job_id)
    if not job_dir.exists():
        raise HTTPException(404, "Job not found")
    status = read_status(job_dir)
    if status.get("state") not in {"queued"}:
        raise HTTPException(409, "Job cannot be canceled")
    queue = get_queue()
    job = queue.fetch_job(job_id)
    if job and job.is_started:
        raise HTTPException(409, "Job already running")
    if job:
        job.cancel()
    update_status(job_dir, state="canceled")
    return {"job_id": job_id, "state": "canceled"}


@app.delete("/jobs/{job_id}")
def delete_job(job_id: str):
    job_dir = job_dir_from_id(job_id)
    if not job_dir.exists():
        raise HTTPException(404, "Job not found")
    shutil.rmtree(job_dir, ignore_errors=True)
    return {"deleted": True}


def read_all_statuses():
    from api_server.storage import list_jobs

    return list_jobs()
