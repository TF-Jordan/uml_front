from __future__ import annotations

import json
import os
import shutil
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional
from datetime import datetime

ALLOWED_STACKS = {"fastapi", "spring", "laravel", "dart", "nestjs", "fiber"}
ALLOWED_MODES = {"class_only", "class_plus_sequence_ia"}
ALLOWED_OVERWRITE = {"none", "backup", "overwrite"}
ALLOWED_AI_PROVIDERS = {"gemini", "claude"}

SPRING_DEPENDENCIES = {
    "lombok",
    "security",
    "actuator",
    "devtools",
}
FASTAPI_DEPS = {
    "httpx",
    "pytest",
    "passlib",
    "python-jose",
    "celery",
    "redis",
}
LARAVEL_DEPS = {
    "laravel/pint",
}
NESTJS_DEPS: set[str] = set()
DART_DEPS: set[str] = set()


def load_config(path: str | Path) -> Dict[str, Any]:
    config_path = Path(path)
    data = json.loads(config_path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("Config root must be an object")
    return data


def apply_defaults(config: Dict[str, Any]) -> Dict[str, Any]:
    meta = config.setdefault("meta", {})
    if "output_dir" not in meta and "output_dir" in config:
        meta["output_dir"] = config.get("output_dir")
    meta.setdefault("schema_version", "1.0")
    meta.setdefault("output_dir", "output")

    pipeline = config.setdefault("pipeline", {})
    pipeline.setdefault("retain_days", 3)
    pipeline.setdefault("overwrite_strategy", "backup")

    ai = config.setdefault("ai", {})
    ai.setdefault("enabled", False)
    if ai.get("enabled"):
        ai.setdefault("provider", "gemini")
        ai.setdefault("max_tokens", 32768)
        ai.setdefault("timeout_seconds", 300)

    stack = meta.get("stack")
    if stack == "spring":
        spring = config.setdefault("spring", {})
        spring.setdefault("java_version", "21")
        spring.setdefault("spring_boot_version", "4.0.1")
        spring.setdefault("build_tool", "maven")
        spring.setdefault("group_id", "com.example")
        spring.setdefault("dependencies", ["lombok"])
        spring.setdefault("db", "mysql")
        spring.setdefault("tests", "junit")
        spring.setdefault("layers", {"controller": True, "service": True, "repository": True, "dto": True})
    elif stack == "fastapi":
        fastapi = config.setdefault("fastapi", {})
        fastapi.setdefault("python_version", "3.12")
        fastapi.setdefault("fastapi_version", "0.128.0")
        fastapi.setdefault("orm", "sqlalchemy")
        fastapi.setdefault("db", "sqlite")
        fastapi.setdefault("migrations", "alembic")
        fastapi.setdefault("auth", "none")
        fastapi.setdefault("deps", [])
        fastapi.setdefault("structure", {"routers": True, "schemas": True, "models": True, "services": True, "repositories": True})
    elif stack == "laravel":
        laravel = config.setdefault("laravel", {})
        laravel.setdefault("php_version", "8.4")
        laravel.setdefault("laravel_version", "12.44.0")
        laravel.setdefault("db", "mysql")
        laravel.setdefault("auth", "sanctum")
        laravel.setdefault("queue", "database")
        laravel.setdefault("cache", "database")
        laravel.setdefault("deps", ["laravel/pint"])
        laravel.setdefault("api_only", True)
    elif stack == "nestjs":
        nestjs = config.setdefault("nestjs", {})
        nestjs.setdefault("node_version", "24.12.0")
        nestjs.setdefault("nest_version", "11.1.x")
        nestjs.setdefault("package_manager", "npm")
        nestjs.setdefault("orm", "typeorm")
        nestjs.setdefault("db", "postgres")
        nestjs.setdefault("auth", "none")
    elif stack == "dart":
        dart = config.setdefault("dart", {})
        dart.setdefault("dart_version", "3.10.x")
        dart.setdefault("framework", "shelf")
        dart.setdefault("db", "postgres")
    elif stack == "fiber":
        fiber = config.setdefault("fiber", {})
        fiber.setdefault("go_version", "1.21")
        fiber.setdefault("fiber_version", "2.52.10")
        fiber.setdefault("db", "postgres")
        fiber.setdefault("orm", "gorm")

    return config


def validate_config(config: Dict[str, Any]) -> List[str]:
    errors: List[str] = []
    meta = config.get("meta", {})
    inputs = config.get("inputs", {})
    pipeline = config.get("pipeline", {})
    ai = config.get("ai", {})

    _require_field(errors, meta, "project_name", "meta.project_name is required")
    _require_field(errors, meta, "stack", "meta.stack is required")
    stack = meta.get("stack")
    if stack and stack not in ALLOWED_STACKS:
        errors.append(f"meta.stack must be one of {sorted(ALLOWED_STACKS)}")

    _require_field(errors, inputs, "class_diagram_path", "inputs.class_diagram_path is required")

    _require_field(errors, pipeline, "mode", "pipeline.mode is required")
    mode = pipeline.get("mode")
    if mode and mode not in ALLOWED_MODES:
        errors.append(f"pipeline.mode must be one of {sorted(ALLOWED_MODES)}")

    overwrite = pipeline.get("overwrite_strategy")
    if overwrite and overwrite not in ALLOWED_OVERWRITE:
        errors.append(f"pipeline.overwrite_strategy must be one of {sorted(ALLOWED_OVERWRITE)}")

    if mode == "class_plus_sequence_ia":
        if not inputs.get("sequence_diagram_path"):
            errors.append("inputs.sequence_diagram_path is required when pipeline.mode=class_plus_sequence_ia")

    if ai.get("enabled"):
        if not ai.get("user_key_id"):
            errors.append("ai.user_key_id is required when ai.enabled=true")
        provider = ai.get("provider")
        if provider and provider not in ALLOWED_AI_PROVIDERS:
            errors.append(f"ai.provider must be one of {sorted(ALLOWED_AI_PROVIDERS)}")
        if mode != "class_plus_sequence_ia":
            errors.append("ai.enabled=true requires pipeline.mode=class_plus_sequence_ia")

    _validate_stack_block(errors, stack, config)
    return errors


def resolve_path(base_dir: Path, value: str | Path | None) -> Optional[Path]:
    if value is None:
        return None
    path = Path(value)
    if not path.is_absolute():
        path = base_dir / path
    return path


def prepare_output_dir(output_dir: Path, strategy: str) -> None:
    if output_dir.exists():
        if strategy == "none":
            raise FileExistsError(f"Output directory already exists: {output_dir}")
        if output_dir.is_file():
            if strategy == "backup":
                backup = _next_backup_path(output_dir)
                output_dir.rename(backup)
            elif strategy == "overwrite":
                output_dir.unlink()
        else:
            if strategy == "backup":
                backup_dir = _next_backup_dir(output_dir)
                backup_dir.mkdir(parents=True, exist_ok=True)
                for item in output_dir.iterdir():
                    if item.name == "_backup":
                        continue
                    shutil.move(str(item), backup_dir / item.name)
            elif strategy == "overwrite":
                shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)


def resolve_ai_key(ai_config: Dict[str, Any]) -> Optional[str]:
    if not ai_config.get("enabled"):
        return None
    user_key_id = ai_config.get("user_key_id")
    if user_key_id:
        direct = os.getenv(user_key_id)
        if direct:
            return direct
    provider = (ai_config.get("provider") or "").lower()
    if provider == "claude":
        return os.getenv("ANTHROPIC_API_KEY")
    if provider == "gemini":
        return os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_GENAI_API_KEY")
    return None


def _require_field(errors: List[str], container: Dict[str, Any], key: str, message: str) -> None:
    value = container.get(key)
    if value is None or (isinstance(value, str) and not value.strip()):
        errors.append(message)


def _next_backup_path(dst: Path) -> Path:
    stem, suffix = dst.stem, dst.suffix
    parent = dst.parent
    candidate = parent / f"{stem}_backup{suffix}"
    idx = 1
    while candidate.exists():
        candidate = parent / f"{stem}_backup{idx}{suffix}"
        idx += 1
    return candidate


def _next_backup_dir(dst: Path) -> Path:
    backup_root = dst / "_backup"
    backup_root.mkdir(parents=True, exist_ok=True)
    stamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    candidate = backup_root / stamp
    idx = 1
    while candidate.exists():
        candidate = backup_root / f"{stamp}_{idx}"
        idx += 1
    return candidate


def _validate_stack_block(errors: List[str], stack: Optional[str], config: Dict[str, Any]) -> None:
    if stack == "spring":
        spring = config.get("spring", {})
        _validate_choice(
            errors,
            spring,
            "spring_boot_version",
            {"4.0.1", "3.5.9", "3.4.13", "3.3.13", "3.2.x"},
            "spring.spring_boot_version",
        )
        _validate_choice(
            errors,
            spring,
            "java_version",
            {"25", "24", "23", "21", "17"},
            "spring.java_version",
        )
        _validate_choice(errors, spring, "build_tool", {"maven"}, "spring.build_tool")
        _validate_choice(errors, spring, "db", {"mysql", "postgres", "mariadb", "h2"}, "spring.db")
        _validate_choice(errors, spring, "tests", {"junit"}, "spring.tests")
        _validate_list(errors, spring.get("dependencies"), SPRING_DEPENDENCIES, "spring.dependencies")
    elif stack == "fastapi":
        fastapi = config.get("fastapi", {})
        _validate_choice(
            errors,
            fastapi,
            "fastapi_version",
            {"0.128.0", "0.125.0", "0.124.4", "0.124.3", "0.124.2", "0.124.1"},
            "fastapi.fastapi_version",
        )
        _validate_choice(
            errors,
            fastapi,
            "python_version",
            {"3.12", "3.13", "3.14", "3.10", "3.9"},
            "fastapi.python_version",
        )
        _validate_choice(
            errors,
            fastapi,
            "orm",
            {"sqlalchemy", "sqlmodel"},
            "fastapi.orm",
        )
        _validate_choice(errors, fastapi, "db", {"sqlite", "postgres", "mysql"}, "fastapi.db")
        _validate_choice(errors, fastapi, "migrations", {"alembic", "none"}, "fastapi.migrations")
        _validate_choice(errors, fastapi, "auth", {"none", "jwt", "oauth"}, "fastapi.auth")
        _validate_list(errors, fastapi.get("deps"), FASTAPI_DEPS, "fastapi.deps")
    elif stack == "laravel":
        laravel = config.get("laravel", {})
        _validate_choice(
            errors,
            laravel,
            "laravel_version",
            {"12.44.0", "12.43.0", "12.42.0", "12.41.0", "12.40.0"},
            "laravel.laravel_version",
        )
        _validate_choice(
            errors,
            laravel,
            "php_version",
            {"8.4", "8.3", "8.2", "8.1"},
            "laravel.php_version",
        )
        _validate_choice(errors, laravel, "db", {"mysql", "pgsql", "sqlite"}, "laravel.db")
        _validate_choice(errors, laravel, "auth", {"sanctum", "passport", "none"}, "laravel.auth")
        _validate_choice(errors, laravel, "queue", {"redis", "database", "none"}, "laravel.queue")
        _validate_choice(errors, laravel, "cache", {"redis", "file", "database"}, "laravel.cache")
        _validate_list(errors, laravel.get("deps"), LARAVEL_DEPS, "laravel.deps")
    elif stack == "nestjs":
        nestjs = config.get("nestjs", {})
        _validate_choice(
            errors,
            nestjs,
            "nest_version",
            {"11.1.x", "11.0.x", "10.9.x", "10.8.x", "10.7.x"},
            "nestjs.nest_version",
        )
        _validate_choice(
            errors,
            nestjs,
            "node_version",
            {"24.12.0", "24.11.0", "25.2.1", "22.21.0", "24.9.0"},
            "nestjs.node_version",
        )
        _validate_choice(errors, nestjs, "package_manager", {"npm"}, "nestjs.package_manager")
        _validate_choice(errors, nestjs, "orm", {"typeorm"}, "nestjs.orm")
        _validate_choice(errors, nestjs, "db", {"postgres", "mysql", "sqlite", "mongodb"}, "nestjs.db")
        _validate_choice(errors, nestjs, "auth", {"none"}, "nestjs.auth")
    elif stack == "dart":
        dart = config.get("dart", {})
        _validate_choice(
            errors,
            dart,
            "dart_version",
            {"3.10.x", "3.9.x", "3.8.x", "3.7.x", "3.6.x"},
            "dart.dart_version",
        )
        _validate_choice(errors, dart, "framework", {"shelf"}, "dart.framework")
        _validate_choice(errors, dart, "db", {"postgres"}, "dart.db")
    elif stack == "fiber":
        fiber = config.get("fiber", {})
        _validate_choice(errors, fiber, "go_version", {"1.21"}, "fiber.go_version")
        _validate_choice(
            errors,
            fiber,
            "fiber_version",
            {"2.52.10", "2.52.9", "2.52.8", "2.52.6", "2.51.x"},
            "fiber.fiber_version",
        )
        _validate_choice(errors, fiber, "db", {"postgres"}, "fiber.db")
        _validate_choice(errors, fiber, "orm", {"gorm"}, "fiber.orm")


def _validate_choice(
    errors: List[str],
    container: Dict[str, Any],
    key: str,
    allowed: Iterable[str],
    label: str,
) -> None:
    if key not in container:
        return
    value = container.get(key)
    if value not in allowed:
        errors.append(f"{label} must be one of {sorted(allowed)}")


def _validate_list(
    errors: List[str],
    value: Any,
    allowed: Iterable[str],
    label: str,
) -> None:
    if value is None:
        return
    if not isinstance(value, list):
        errors.append(f"{label} must be a list")
        return
    allowed_set = set(allowed)
    for item in value:
        if item not in allowed_set:
            errors.append(f"{label} contains unsupported entry: {item}")
