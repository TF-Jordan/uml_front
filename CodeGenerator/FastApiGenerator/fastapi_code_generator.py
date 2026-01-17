import json
import datetime
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

from jinja2 import Environment, FileSystemLoader

from helpers.utils import Utils


TYPE_MAP = {
    "int": "int",
    "integer": "int",
    "long": "int",
    "float": "float",
    "double": "float",
    "decimal": "float",
    "bigdecimal": "float",
    "string": "str",
    "text": "str",
    "char": "str",
    "bool": "bool",
    "boolean": "bool",
    "uuid": "str",
    "localdate": "datetime.date",
    "date": "datetime.date",
    "localdatetime": "datetime.datetime",
    "datetime": "datetime.datetime",
    "time": "datetime.time",
}


SQLA_TYPE_MAP = {
    "int": "Integer",
    "float": "Float",
    "str": "String",
    "bool": "Boolean",
    "datetime.datetime": "DateTime",
    "datetime.date": "Date",
    "datetime.time": "Time",
}


class FastApiCodeGenerator:
    """Génère un squelette FastAPI minimal à partir du JSON normalisé."""

    def __init__(self, output_root: Path | str | None = None, options: Dict[str, Any] | None = None) -> None:
        self.templates_dir = Path(__file__).resolve().parents[1] / "Templates" / "FastApi"
        self.output_root = Path(output_root or Path("GeneratedProject") / "FastApi")
        self.env = Environment(loader=FileSystemLoader(self.templates_dir))
        self.options = options or {}

    def generate_project(self, project_name: str, project_payload: Dict[str, Any]) -> None:
        project_dir = self.output_root / project_name
        base_module = self._resolve_base_package(project_name)
        app_dir = self._ensure_package_root(project_dir, base_module)
        routers_dir = app_dir / "routers"
        schemas_dir = app_dir / "schemas"
        models_dir = app_dir / "models"
        services_dir = app_dir / "services"
        repositories_dir = app_dir / "repositories"
        core_dir = app_dir / "core"
        config_dir = app_dir / "config"
        tests_dir = project_dir / "tests"
        resources_dir = project_dir / "resources"
        orm = (self.options.get("orm") or "sqlalchemy").lower()
        self._ensure_dir(routers_dir)
        self._ensure_dir(schemas_dir)
        self._ensure_dir(models_dir)
        for extra in (
            services_dir,
            repositories_dir,
            core_dir,
            config_dir,
            tests_dir,
            resources_dir,
        ):
            self._ensure_dir(extra)
            (extra / "__init__.py").write_text("", encoding="utf-8")
        # db.py
        self._render_template(
            "db.py.j2",
            app_dir / "db.py",
            orm=orm,
            base_module=base_module,
        )

        raw_classes = project_payload.get("classes", {})
        classes = self._normalize_classes(raw_classes)
        router_modules: List[str] = []
        model_modules: List[Dict[str, str]] = []

        for class_name, class_payload in classes.items():
            schema_module = self._snake_case(class_name)
            router_modules.append(schema_module)
            attributes = class_payload.get("attributes", [])
            model_modules.append({"module": schema_module, "class_name": class_name})

            self._render_template(
                "schema.py.j2",
                schemas_dir / f"{schema_module}.py",
                class_name=class_name,
                attributes=attributes,
            )
            self._render_template(
                "model.py.j2",
                models_dir / f"{schema_module}.py",
                class_name=class_name,
                table_name=self._snake_case(class_name),
                attributes=attributes,
                extends=class_payload.get("extends"),
                extends_module=self._snake_case(class_payload.get("extends")) if class_payload.get("extends") else None,
                orm=orm,
                base_module=base_module,
            )
            self._render_template(
                "router.py.j2",
                routers_dir / f"{schema_module}.py",
                class_name=class_name,
                schema_module=schema_module,
                route=schema_module,
                route_singular=schema_module.rstrip("s"),
                orm=orm,
                base_module=base_module,
            )

        self._render_template(
            "routers_init.py.j2",
            routers_dir / "__init__.py",
            router_modules=router_modules,
            base_module=base_module,
        )
        self._render_template(
            "main.py.j2",
            app_dir / "main.py",
            project_name=project_name,
            model_modules=model_modules,
            base_module=base_module,
        )
        # Registre des modèles pour l'init des tables
        models_init = "\n".join(
            f"from {base_module}.models.{item['module']} import {item['class_name']}" for item in model_modules
        )
        models_init += "\n\n__all__ = [{}]\n".format(
            ", ".join(f"'{item['class_name']}'" for item in model_modules)
        )
        (models_dir / "__init__.py").write_text(models_init, encoding="utf-8")
        # fichiers de config de base
        (config_dir / "settings.py").write_text("from pydantic import BaseSettings\n\nclass Settings(BaseSettings):\n    app_name: str = \"{}\"\n\nsettings = Settings()\n".format(project_name), encoding="utf-8")
        (core_dir / "security.py").write_text("", encoding="utf-8")
        self._write_requirements(project_dir)
        self._dump_project_json(project_name, project_payload, project_dir)

    def _ensure_package_root(self, project_dir: Path, base_module: str) -> Path:
        parts = [part for part in base_module.split(".") if part]
        current = project_dir
        for part in parts:
            current = current / part
            self._ensure_dir(current)
            init_file = current / "__init__.py"
            if not init_file.exists():
                init_file.write_text("", encoding="utf-8")
        return current

    def _resolve_base_package(self, project_name: str) -> str:
        raw = (self.options.get("package_name") or "").strip()
        if not raw:
            return "app"
        return self._sanitize_package(raw, fallback=project_name)

    def _sanitize_package(self, value: str, fallback: str) -> str:
        cleaned = value.strip().replace("/", ".")
        parts = [p for p in re.split(r"[.]+", cleaned) if p]
        normalized = []
        for part in parts:
            part = re.sub(r"[^A-Za-z0-9_]", "_", part).lower()
            part = re.sub(r"_+", "_", part).strip("_")
            if not part:
                continue
            if part[0].isdigit():
                part = f"pkg_{part}"
            normalized.append(part)
        if not normalized:
            return self._sanitize_package(fallback, fallback)
        return ".".join(normalized)

    def _normalize_classes(self, classes: Dict[str, Any]) -> Dict[str, Any]:
        """Déduit les relations (collection -> one-to-many, double collection -> many-to-many, type = classe -> many-to-one)."""
        class_names = set(classes.keys())
        normalized: Dict[str, Any] = {}
        pending_collections: List[Dict[str, str]] = []

        for class_name, payload in classes.items():
            attrs: List[Dict[str, Any]] = []
            has_id = False
            type_descriptor = Utils.parse_class_descriptor(payload.get("type"))
            for attr in payload.get("attributes", []):
                raw_name = attr.get("attribute_name") or attr.get("name") or ""
                raw_type = (attr.get("attribute_type") or attr.get("type") or "str").strip()
                relation_hint = self._relation_hint(raw_name, raw_type)
                cleaned_name = self._snake_case(self._clean_value(raw_name))
                cleaned_type = self._clean_value(raw_type)
                collection_of = self._extract_collection_type(cleaned_type)
                type_hint = TYPE_MAP.get(cleaned_type.lower(), "str")

                is_primary = cleaned_name == "id"
                has_id = has_id or is_primary

                relation_kind = None
                target_class = None
                target_table = None
                column_name = cleaned_name
                column_type = self._sa_column_type(type_hint)
                nullable_db = attr.get("visibility") != "public"

                if collection_of and collection_of in class_names:
                    relation_kind = "one_to_many"
                    target_class = collection_of
                    target_table = self._snake_case(target_class)
                    nullable_db = relation_hint != "composition"
                    pending_collections.append(
                        {"owner": class_name, "attr": cleaned_name, "target": target_class}
                    )
                elif cleaned_type in class_names:
                    relation_kind = "many_to_one"
                    target_class = cleaned_type
                    target_table = self._snake_case(target_class)
                    column_name = f"{cleaned_name}_id"
                    column_type = self._infer_fk_column_type(classes.get(target_class)) or "Integer"
                    type_hint = "int"
                    nullable_db = relation_hint != "composition"

                if is_primary:
                    nullable_db = False

                attrs.append(
                    {
                        "name": cleaned_name,
                        "schema_name": column_name,
                        "type": type_hint,
                        "optional_schema": nullable_db or is_primary,
                        "nullable_db": nullable_db,
                        "is_primary": is_primary,
                        "relation_kind": relation_kind,
                        "target_class": target_class,
                        "target_table": target_table,
                        "column_name": column_name,
                        "column_type": column_type,
                        "relation_hint": relation_hint,
                        "join_table": None,
                        "inverse_join_column": None,
                    }
                )

            if not has_id:
                attrs.insert(
                    0,
                    {
                        "name": "id",
                        "schema_name": "id",
                        "type": "int",
                        "optional_schema": True,
                        "nullable_db": False,
                        "is_primary": True,
                        "relation_kind": None,
                        "target_class": None,
                        "target_table": None,
                        "column_name": "id",
                        "column_type": "Integer",
                        "relation_hint": None,
                        "join_table": None,
                        "inverse_join_column": None,
                    },
                )

            new_payload = payload.copy()
            new_payload["attributes"] = attrs
            new_payload["class_type"] = type_descriptor.get("class_type")
            new_payload["extends"] = type_descriptor.get("extends")
            new_payload["implements"] = type_descriptor.get("implements")
            new_payload["original_name"] = payload.get("name") or class_name
            normalized[class_name] = new_payload

        # Convert mutual one_to_many to many_to_many
        for item in pending_collections:
            reverse = self._find_relation(normalized, item["target"], item["owner"], "one_to_many")
            if reverse:
                self._set_many_to_many(normalized, item["owner"], item["attr"], item["target"])
                self._set_many_to_many(normalized, item["target"], reverse["name"], item["owner"])

        return normalized

    def _render_template(self, template_name: str, output_path: Path, **context: Any) -> None:
        template = self.env.get_template(template_name)
        rendered = template.render(**context)
        self._ensure_dir(output_path.parent)
        output_path.write_text(rendered, encoding="utf-8")

    def _write_requirements(self, project_dir: Path) -> None:
        fastapi_version = self.options.get("fastapi_version", "0.128.0")
        orm = (self.options.get("orm") or "sqlalchemy").lower()
        base = [
            f"fastapi=={fastapi_version}",
            "uvicorn[standard]==0.32.1",
            "pydantic==2.9.2",
            "python-multipart==0.0.9",
        ]
        if orm == "sqlmodel":
            base.append("sqlmodel==0.0.24")
        else:
            base.append("sqlalchemy==2.0.36")
        extras = set(self.options.get("deps", []) or [])
        if self.options.get("migrations") == "alembic":
            extras.add("alembic")
        if self.options.get("auth") in {"jwt", "oauth"}:
            extras.update({"passlib", "python-jose"})
        content = "\n".join(base + sorted(extras))
        (project_dir / "requirements.txt").write_text(content, encoding="utf-8")

    def _dump_project_json(
        self,
        project_name: str,
        project_payload: Dict[str, Any],
        project_dir: Path,
    ) -> Path:
        json_path = project_dir / f"{project_name}_normalized.json"
        serialized = {project_name: project_payload}
        json_path.write_text(json.dumps(serialized, indent=2, ensure_ascii=False), encoding="utf-8")
        return json_path

    def _ensure_dir(self, path: Path) -> None:
        path.mkdir(parents=True, exist_ok=True)

    def _snake_case(self, value: str) -> str:
        return "".join(ch.lower() if ch.isalnum() else "_" for ch in value or "").strip("_")

    def _clean_value(self, value: str) -> str:
        return value.replace("$", "").replace("#", "").strip()

    def _relation_hint(self, raw_name: str, raw_type: str) -> str | None:
        if "$" in raw_name or "$" in raw_type:
            return "composition"
        if "#" in raw_name or "#" in raw_type:
            return "aggregation"
        return None

    def _sa_column_type(self, type_hint: str) -> str:
        return SQLA_TYPE_MAP.get(type_hint, "String")

    def _infer_fk_column_type(self, target_payload: Dict[str, Any] | None) -> Optional[str]:
        if not target_payload:
            return None
        for attr in target_payload.get("attributes", []):
            name = attr.get("attribute_name") or attr.get("name")
            if (name or "").lower() == "id":
                raw_type = attr.get("attribute_type") or attr.get("type") or "int"
                mapped = TYPE_MAP.get(raw_type.lower(), "int")
                return self._sa_column_type(mapped)
        return None

    def _extract_collection_type(self, raw_type: str) -> Optional[str]:
        cleaned = raw_type.replace(" ", "")
        if "<" in cleaned and ">" in cleaned:
            return cleaned[cleaned.find("<") + 1 : cleaned.rfind(">")] or None
        if cleaned.endswith("[]"):
            return cleaned[:-2] or None
        lower = cleaned.lower()
        for prefix in ("listof", "setof"):
            if lower.startswith(prefix):
                return cleaned[len(prefix) :]
        return None

    def _find_relation(self, normalized: Dict[str, Any], class_name: str, target: str, relation: str) -> Optional[Dict[str, Any]]:
        payload = normalized.get(class_name, {})
        for attr in payload.get("attributes", []):
            if attr.get("relation_kind") == relation and attr.get("target_class") == target:
                return attr
        return None

    def _set_many_to_many(self, normalized: Dict[str, Any], class_name: str, attr_name: str, target: str) -> None:
        payload = normalized.get(class_name, {})
        join_table = f"{self._snake_case(class_name)}_{self._snake_case(target)}"
        for attr in payload.get("attributes", []):
            if attr.get("name") == attr_name:
                attr["relation_kind"] = "many_to_many"
                attr["join_table"] = join_table
                attr["column_name"] = attr.get("column_name") or f"{self._snake_case(class_name)}_id"
                attr["inverse_join_column"] = f"{self._snake_case(target)}_id"


__all__ = ["FastApiCodeGenerator"]
