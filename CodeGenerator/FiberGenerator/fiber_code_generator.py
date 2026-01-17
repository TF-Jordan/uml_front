import json
from pathlib import Path
from typing import Any, Dict, List, Optional
from jinja2 import Environment, FileSystemLoader

# Correspondance type JSON -> Go
TYPE_MAP = {
    "int": "int",
    "integer": "int",
    "long": "int64",
    "float": "float32",
    "double": "float64",
    "decimal": "float64",
    "bigdecimal": "float64",
    "string": "string",
    "text": "string",
    "char": "string",
    "bool": "bool",
    "boolean": "bool",
    "uuid": "string",
    "localdate": "time.Time",
    "date": "time.Time",
    "localdatetime": "time.Time",
    "datetime": "time.Time",
    "time": "time.Time",
}

GORM_TYPE_MAP = {
    "int": "type:int",
    "int64": "type:bigint",
    "float32": "type:float",
    "float64": "type:decimal(10,2)",
    "string": "type:varchar(255)",
    "bool": "type:boolean",
    "time.Time": "type:timestamp",
}

class FiberCodeGenerator:
    """Génère un squelette Go/Fiber avec GORM à partir du JSON normalisé."""

    def __init__(self, output_root: Path | str | None = None, options: Dict[str, Any] | None = None) -> None:
        self.templates_dir = Path(__file__).resolve().parents[1] / "Templates" / "Fiber"
        self.output_root = Path(output_root or Path("GeneratedProject") / "Fiber")
        self.env = Environment(loader=FileSystemLoader(self.templates_dir))
        self.options = options or {}

    def generate_project(self, project_name: str, project_payload: Dict[str, Any]) -> None:
        project_dir = self.output_root / project_name
        dirs = ["models", "handlers", "services", "repositories", "config", "routes", "utils"]
        for d in dirs:
            self._ensure_dir(project_dir / d)

        module_path = self._resolve_module_path(project_name)
        go_version = self.options.get("go_version", "1.21")
        fiber_version = self._normalize_semver(self.options.get("fiber_version", "2.52.10"))

        # Templates génériques
        self._render_template(
            "main.go.j2",
            project_dir / "main.go",
            project_name=project_name,
            module_path=module_path,
        )

        self._render_template(
            "go.mod.j2",
            project_dir / "go.mod",
            module_path=module_path,
            go_version=go_version,
            fiber_version=fiber_version,
        )

        # Normalisation des classes
        raw_classes = project_payload.get("classes", {})
        classes = self._normalize_classes(raw_classes)

        model_names = [
            class_name[0].upper() + class_name[1:]
            for class_name in classes.keys()
        ]

        self._render_template("database.go.j2",
                              project_dir / "config" / "database.go",
                              models=model_names,
                              module_path=module_path)

        # Génération code par classe
        for class_name, class_payload in classes.items():
            class_name_go = class_name[0].upper() + class_name[1:]
            snake_name = self._snake_case(class_name)
            attributes = class_payload["attributes"]

            # Préparer id_attr
            id_attr = next((a for a in attributes if a.get("is_primary")), None)
            if id_attr is None:
                raise Exception(f"Classe {class_name} n'a pas d'attribut primaire défini")

            # Model
            self._render_template(
                "model.go.j2",
                project_dir / "models" / f"{snake_name}.go",
                class_name=class_name_go,
                table_name=snake_name,
                attributes=attributes,
                id_attr=id_attr,
            )

            # Repository
            self._render_template(
                "repository.go.j2",
                project_dir / "repositories" / f"{snake_name}_repository.go",
                class_name=class_name_go,
                snake_name=snake_name,
                id_attr=id_attr,
                module_path=module_path,
            )

            # Handler
            self._render_template(
                "handler.go.j2",
                project_dir / "handlers" / f"{snake_name}_handler.go",
                class_name=class_name_go,
                snake_name=snake_name,
                id_attr=id_attr,
                attributes=attributes,
                module_path=module_path,
            )

            # Service
            self._render_template(
                "service.go.j2",
                project_dir / "services" / f"{snake_name}_service.go",
                class_name=class_name_go,
                snake_name=snake_name,
                module_path=module_path,
                id_attr=id_attr,
            )

        # Routes
        handler_routes = [{"name": c[0].upper() + c[1:], "snake": self._snake_case(c)} for c in classes.keys()]
        self._render_template(
            "routes.go.j2",
            project_dir / "routes" / "routes.go",
            handler_routes=handler_routes,
            module_path=module_path
        )

        self._write_env_example(project_dir)
        self._write_readme(project_dir, project_name)
        self._dump_project_json(project_name, project_payload, project_dir)

    def _resolve_module_path(self, project_name: str) -> str:
        raw = (self.options.get("package_name") or "").strip()
        if not raw:
            return self._sanitize_module_path(project_name)
        return self._sanitize_module_path(raw)

    def _sanitize_module_path(self, value: str) -> str:
        cleaned = value.strip().replace(" ", "")
        cleaned = cleaned.strip("/")
        cleaned = cleaned.replace("\\", "/")
        if not cleaned:
            return "module"
        return cleaned

    # -------------------
    # Normalisation des classes
    # -------------------
    def _normalize_classes(self, classes: Dict[str, Any]) -> Dict[str, Any]:
        normalized: Dict[str, Any] = {}
        class_names = set(classes.keys())

        for class_name, payload in classes.items():
            attrs: List[Dict[str, Any]] = []
            has_id = False

            for attr in payload.get("attributes", []):
                raw_name = attr.get("attribute_name") or attr.get("name") or ""
                raw_type = (attr.get("attribute_type") or attr.get("type") or "string").strip()
                visibility = attr.get("visibility", "+")

                cleaned_name = self._clean_value(raw_name)
                type_hint = TYPE_MAP.get(raw_type.lower(), "string")

                go_name = "ID" if cleaned_name.lower() == "id" else self._to_pascal_case(cleaned_name)
                json_tag = self._snake_case(cleaned_name)
                is_primary = cleaned_name.lower() == "id"
                has_id = has_id or is_primary
                is_exported = visibility == "+"
                gorm_tag = "primaryKey" if is_primary else GORM_TYPE_MAP.get(type_hint, "type:varchar(255)")

                attrs.append({
                    "raw_name": cleaned_name,
                    "go_name": go_name,
                    "type": type_hint,
                    "json_tag": json_tag,
                    "gorm_tag": gorm_tag,
                    "is_primary": is_primary,
                    "is_exported": is_exported,
                })

            # Si pas d'ID trouvé, ajouter un uint auto-increment
            if not has_id:
                attrs.insert(0, {
                    "raw_name": "id",
                    "go_name": "ID",
                    "type": "uint",
                    "json_tag": "id",
                    "gorm_tag": "primaryKey;autoIncrement",
                    "is_primary": True,
                    "is_exported": True,
                })

            # Ajouter CreatedAt / UpdatedAt
            attrs.extend([
                {"raw_name": "created_at", "go_name": "CreatedAt", "type": "time.Time",
                 "json_tag": "created_at", "gorm_tag": "autoCreateTime", "is_primary": False, "is_exported": True},
                {"raw_name": "updated_at", "go_name": "UpdatedAt", "type": "time.Time",
                 "json_tag": "updated_at", "gorm_tag": "autoUpdateTime", "is_primary": False, "is_exported": True},
            ])

            normalized[class_name] = {"attributes": attrs}

        return normalized

    @staticmethod
    def _normalize_semver(version: str) -> str:
        cleaned = version.strip()
        if cleaned.startswith("~"):
            cleaned = cleaned[1:]
        if cleaned.endswith(".x"):
            return f"{cleaned[:-2]}.0"
        return cleaned

    # -------------------
    # Fonctions utilitaires
    # -------------------
    def _render_template(self, template_name: str, output_path: Path, **context: Any) -> None:
        template = self.env.get_template(template_name)
        rendered = template.render(**context)
        self._ensure_dir(output_path.parent)
        output_path.write_text(rendered, encoding="utf-8")

    def _ensure_dir(self, path: Path) -> None:
        path.mkdir(parents=True, exist_ok=True)

    def _snake_case(self, value: str) -> str:
        result = ""
        for i, ch in enumerate(value or ""):
            if ch.isupper() and i > 0 and result and result[-1] != "_":
                result += "_"
            result += ch.lower() if ch.isalnum() else "_"
        return result.strip("_")

    def _to_pascal_case(self, value: str) -> str:
        return "".join(w.capitalize() for w in value.replace("_", " ").split())

    def _clean_value(self, value: str) -> str:
        return value.replace("$", "").replace("#", "").strip()

    def _write_env_example(self, project_dir: Path) -> None:
        content = "DB_HOST=localhost\nDB_PORT=5432\nDB_USER=postgres\nDB_PASSWORD=password\nDB_NAME=mydatabase\nSERVER_PORT=3000\n"
        (project_dir / ".env").write_text(content, encoding="utf-8")

    def _write_readme(self, project_dir: Path, project_name: str) -> None:
        content = (f"# {project_name}\n\nRun with `go run main.go \n"
                   f"# Download dependencies with\n go mod tidy ` \n "
                   f" `go mod download` \n `")
        (project_dir / "README.md").write_text(content, encoding="utf-8")

    def _dump_project_json(self, project_name: str, project_payload: Dict[str, Any], project_dir: Path) -> None:
        json_path = project_dir / f"{project_name}_normalized.json"
        serialized = {project_name: project_payload}
        json_path.write_text(json.dumps(serialized, indent=2), encoding="utf-8")
