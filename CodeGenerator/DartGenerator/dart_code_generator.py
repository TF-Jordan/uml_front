import json
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

from jinja2 import Environment, FileSystemLoader


# Mapping UML types -> Dart types
DART_TYPE_MAP = {
    "int": "int",
    "integer": "int",
    "long": "int",
    "float": "double",
    "double": "double",
    "decimal": "double",
    "bigdecimal": "double",
    "string": "String",
    "str": "String",
    "text": "String",
    "char": "String",
    "bool": "bool",
    "boolean": "bool",
    "uuid": "String",
    "localdate": "DateTime",
    "date": "DateTime",
    "localdatetime": "DateTime",
    "datetime": "DateTime",
    "time": "DateTime",
}

# Mapping Dart types -> JSON serialization
JSON_TYPE_MAP = {
    "int": "int",
    "double": "double",
    "String": "String",
    "bool": "bool",
    "DateTime": "String",  # DateTime serialized as ISO string
}


class DartCodeGenerator:
    """
    Generates a complete Dart backend project structure from normalized JSON.
    Uses Shelf + shelf_router with Repository pattern, Service layer, and clean architecture.
    """

    def __init__(self, output_root: Path | str | None = None, options: Dict[str, Any] | None = None) -> None:
        self.templates_dir = Path(__file__).resolve().parents[1] / "Templates" / "Dart"
        self.static_dir = self.templates_dir / "static"
        self.output_root = Path(output_root or Path("GeneratedProject") / "Dart")
        self.env = Environment(loader=FileSystemLoader(self.templates_dir))
        self.env.filters['snake_case'] = self._snake_case
        self.env.filters['plural'] = self._plural
        self.env.filters['camel_case'] = self._camel_case
        self.env.filters['pascal_case'] = self._pascal_case
        self.env.filters['lcfirst'] = self._lcfirst
        self.options = options or {}

    def generate_project(self, project_name: str, project_payload: Dict[str, Any]) -> Path:
        """Main entry point - generates complete Dart backend project."""
        raw_classes = project_payload.get("classes", {})
        classes = self._normalize_classes(raw_classes)

        project_slug = self._slug(project_name)
        package_name = self._resolve_package_name(project_name, project_slug)
        project_dir = self.output_root / project_slug

        # Create directory structure
        self._create_directory_structure(project_dir)

        # Copy static files
        self._copy_static_files(project_dir)

        # Generate project-level files
        self._generate_project_files(
            project_dir,
            project_name,
            project_slug,
            package_name,
            classes,
        )

        # Generate class-specific files
        for class_name, class_payload in classes.items():
            self._generate_class_files(project_dir, class_name, class_payload, classes)

        # Dump normalized JSON for reference
        self._dump_project_json(project_name, project_payload, project_dir)

        return project_dir

    def _create_directory_structure(self, project_dir: Path) -> None:
        """Creates the Dart backend directory structure."""
        directories = [
            # Binary (entry point)
            "bin",
            # Library source
            "lib/src/config",
            "lib/src/models",
            "lib/src/repositories",
            "lib/src/services",
            "lib/src/controllers",
            "lib/src/routes",
            "lib/src/middleware",
            "lib/src/utils",
            # Tests
            "test",
        ]

        for directory in directories:
            (project_dir / directory).mkdir(parents=True, exist_ok=True)

    def _copy_static_files(self, project_dir: Path) -> None:
        """Copies static Dart files from templates/static directory."""
        if not self.static_dir.exists():
            return

        for src_file in self.static_dir.rglob("*"):
            if src_file.is_file():
                relative_path = src_file.relative_to(self.static_dir)
                dest_file = project_dir / relative_path
                dest_file.parent.mkdir(parents=True, exist_ok=True)
                dest_file.write_text(src_file.read_text(encoding="utf-8"), encoding="utf-8")

    def _generate_project_files(
        self,
        project_dir: Path,
        project_name: str,
        project_slug: str,
        package_name: str,
        classes: Dict[str, Any]
    ) -> None:
        """Generates project-level files."""
        class_list = list(classes.keys())
        dart_version = self.options.get("dart_version", "3.10.x")
        dart_sdk_constraint = self._build_sdk_constraint(dart_version)

        # bin/server.dart - Entry point
        self._render_template(
            "project/server.dart.j2",
            project_dir / "bin" / "server.dart",
            project_name=project_name,
            package_name=package_name,
        )

        # lib/app.dart - Main app configuration
        self._render_template(
            "project/app.dart.j2",
            project_dir / "lib" / "app.dart",
            classes=class_list,
        )

        # lib/src/routes/api_routes.dart - Route definitions
        self._render_template(
            "project/api_routes.dart.j2",
            project_dir / "lib" / "src" / "routes" / "api_routes.dart",
            classes=class_list,
        )

        # lib/src/config/database_config.dart
        self._render_template(
            "project/database_config.dart.j2",
            project_dir / "lib" / "src" / "config" / "database_config.dart",
        )

        # lib/src/middleware/cors_middleware.dart
        self._render_template(
            "project/cors_middleware.dart.j2",
            project_dir / "lib" / "src" / "middleware" / "cors_middleware.dart",
        )

        # lib/src/middleware/json_middleware.dart
        self._render_template(
            "project/json_middleware.dart.j2",
            project_dir / "lib" / "src" / "middleware" / "json_middleware.dart",
        )

        # lib/src/utils/response_utils.dart
        self._render_template(
            "project/response_utils.dart.j2",
            project_dir / "lib" / "src" / "utils" / "response_utils.dart",
        )

        # pubspec.yaml
        self._render_template(
            "project/pubspec.yaml.j2",
            project_dir / "pubspec.yaml",
            project_name=project_name,
            project_slug=project_slug,
            package_name=package_name,
            dart_version=dart_version,
            dart_sdk_constraint=dart_sdk_constraint,
        )

        # analysis_options.yaml
        self._render_template(
            "project/analysis_options.yaml.j2",
            project_dir / "analysis_options.yaml",
        )

        # README.md
        self._render_template(
            "project/readme.md.j2",
            project_dir / "README.md",
            project_name=project_name,
            classes=class_list,
            dart_version=dart_version,
        )

        # .env and .env.example
        for env_file in [".env", ".env.example"]:
            self._render_template(
                "project/env.j2",
                project_dir / env_file,
                project_name=project_name,
                project_slug=project_slug,
            )

    def _generate_class_files(
        self,
        project_dir: Path,
        class_name: str,
        class_payload: Dict[str, Any],
        all_classes: Dict[str, Any],
    ) -> None:
        """Generates all files for a single model."""
        attributes = class_payload.get("attributes", [])
        file_name = self._snake_case(class_name)

        # Model
        self._render_template(
            "dynamic/model.dart.j2",
            project_dir / "lib" / "src" / "models" / f"{file_name}.dart",
            class_name=class_name,
            attributes=attributes,
            all_classes=all_classes,
        )

        # Repository
        self._render_template(
            "dynamic/repository.dart.j2",
            project_dir / "lib" / "src" / "repositories" / f"{file_name}_repository.dart",
            class_name=class_name,
            file_name=file_name,
        )

        # Service
        self._render_template(
            "dynamic/service.dart.j2",
            project_dir / "lib" / "src" / "services" / f"{file_name}_service.dart",
            class_name=class_name,
            file_name=file_name,
        )

        # Controller
        self._render_template(
            "dynamic/controller.dart.j2",
            project_dir / "lib" / "src" / "controllers" / f"{file_name}_controller.dart",
            class_name=class_name,
            file_name=file_name,
        )

    def _normalize_classes(self, classes: Dict[str, Any]) -> Dict[str, Any]:
        """Normalizes classes: cleans attributes, infers relations, adds id if missing."""
        class_names = set(classes.keys())
        normalized: Dict[str, Any] = {}
        pending_relations: List[Dict[str, str]] = []

        for class_name, payload in classes.items():
            attrs: List[Dict[str, Any]] = []
            has_id = False

            for attr in payload.get("attributes", []):
                raw_name = attr.get("attribute_name") or attr.get("name") or ""
                raw_type = (attr.get("attribute_type") or attr.get("type") or "string").strip()

                relation_hint = self._relation_hint(raw_name, raw_type)
                cleaned_name = self._clean_value(raw_name)
                cleaned_type = self._clean_value(raw_type)
                collection_of = self._extract_collection_type(cleaned_type)

                dart_type = self._map_dart_type(cleaned_type)
                json_type = JSON_TYPE_MAP.get(dart_type, "dynamic")

                is_primary = cleaned_name.lower() == "id"
                has_id = has_id or is_primary

                relation_kind = None
                target_class = None
                nullable = attr.get("visibility") != "public"

                # Collection -> one_to_many candidate
                if collection_of and collection_of in class_names:
                    relation_kind = "one_to_many"
                    target_class = collection_of
                    nullable = relation_hint != "composition"
                    pending_relations.append({
                        "owner": class_name,
                        "attr": cleaned_name,
                        "target": target_class,
                    })
                # Direct class reference -> many_to_one
                elif cleaned_type in class_names:
                    relation_kind = "many_to_one"
                    target_class = cleaned_type
                    nullable = relation_hint != "composition"

                if is_primary:
                    nullable = False
                    dart_type = "int"

                attrs.append({
                    "name": cleaned_name,
                    "camel_name": self._camel_case(cleaned_name),
                    "snake_name": self._snake_case(cleaned_name),
                    "type": dart_type,
                    "json_type": json_type,
                    "nullable": nullable,
                    "is_primary": is_primary,
                    "relation_kind": relation_kind,
                    "relation_hint": relation_hint,
                    "target_class": target_class,
                    "is_date": dart_type == "DateTime",
                })

            # Add id if missing
            if not has_id:
                attrs.insert(0, {
                    "name": "id",
                    "camel_name": "id",
                    "snake_name": "id",
                    "type": "int",
                    "json_type": "int",
                    "nullable": False,
                    "is_primary": True,
                    "relation_kind": None,
                    "relation_hint": None,
                    "target_class": None,
                    "is_date": False,
                })

            new_payload = payload.copy()
            new_payload["attributes"] = attrs
            normalized[class_name] = new_payload

        # Upgrade mutual one_to_many to many_to_many
        for item in pending_relations:
            reverse = self._find_relation(normalized, item["target"], item["owner"], "one_to_many")
            if reverse:
                self._set_many_to_many(normalized, item["owner"], item["attr"], item["target"])
                self._set_many_to_many(normalized, item["target"], reverse["name"], item["owner"])

        return normalized

    def _render_template(self, template_name: str, output_path: Path, **context: Any) -> None:
        """Renders a Jinja2 template to the specified output path."""
        template = self.env.get_template(template_name)
        rendered = template.render(**context)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(rendered, encoding="utf-8")

    def _dump_project_json(
        self,
        project_name: str,
        project_payload: Dict[str, Any],
        project_dir: Path,
    ) -> Path:
        """Saves the normalized JSON for reference."""
        json_path = project_dir / f"{self._slug(project_name)}_normalized.json"
        serialized = {project_name: project_payload}
        json_path.write_text(json.dumps(serialized, indent=2, ensure_ascii=False), encoding="utf-8")
        return json_path

    # ========================
    # Helper methods
    # ========================

    def _slug(self, name: str) -> str:
        """Converts project name to slug (lowercase, alphanumeric, underscores for Dart)."""
        return re.sub(r'[^a-z0-9]+', '_', name.lower()).strip('_')

    def _resolve_package_name(self, project_name: str, fallback: str) -> str:
        raw = (self.options.get("package_name") or "").strip()
        if not raw:
            return fallback
        candidate = self._slug(raw)
        return candidate or fallback

    def _snake_case(self, value: str) -> str:
        """Converts PascalCase/camelCase to snake_case."""
        if not value:
            return ""
        s1 = re.sub(r'(.)([A-Z][a-z]+)', r'\1_\2', value)
        return re.sub(r'([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

    def _camel_case(self, value: str) -> str:
        """Converts to camelCase."""
        if not value:
            return ""
        snake = self._snake_case(value)
        words = snake.split('_')
        return words[0].lower() + ''.join(word.capitalize() for word in words[1:])

    def _pascal_case(self, value: str) -> str:
        """Converts to PascalCase."""
        if not value:
            return ""
        snake = self._snake_case(value)
        words = snake.split('_')
        return ''.join(word.capitalize() for word in words)

    def _lcfirst(self, value: str) -> str:
        """Lowercases the first character only."""
        if not value:
            return ""
        return value[0].lower() + value[1:] if len(value) > 1 else value.lower()

    def _plural(self, value: str) -> str:
        """Simple English pluralization."""
        if not value:
            return ""
        if value.endswith('y') and len(value) > 1 and value[-2] not in 'aeiou':
            return value[:-1] + 'ies'
        if value.endswith(('s', 'x', 'z', 'ch', 'sh')):
            return value + 'es'
        return value + 's'

    def _clean_value(self, value: str) -> str:
        """Removes special chars ($, #) from value."""
        return value.replace("$", "").replace("#", "").strip()

    def _relation_hint(self, raw_name: str, raw_type: str) -> Optional[str]:
        """Extracts relation hint from $ or # markers."""
        if "$" in raw_name or "$" in raw_type:
            return "composition"
        if "#" in raw_name or "#" in raw_type:
            return "aggregation"
        return None

    def _extract_collection_type(self, raw_type: str) -> Optional[str]:
        """Extracts inner type from collection notation."""
        cleaned = raw_type.replace(" ", "")
        if "<" in cleaned and ">" in cleaned:
            return cleaned[cleaned.find("<") + 1:cleaned.rfind(">")] or None
        if cleaned.endswith("[]"):
            return cleaned[:-2] or None
        lower = cleaned.lower()
        for prefix in ("listof", "setof"):
            if lower.startswith(prefix):
                return cleaned[len(prefix):]
        return None

    def _map_dart_type(self, raw_type: str) -> str:
        """Maps UML type to Dart type."""
        lower = raw_type.lower()
        return DART_TYPE_MAP.get(lower, "String")

    def _find_relation(
        self,
        normalized: Dict[str, Any],
        class_name: str,
        target: str,
        relation: str
    ) -> Optional[Dict[str, Any]]:
        """Finds a relation attribute in a class."""
        payload = normalized.get(class_name, {})
        for attr in payload.get("attributes", []):
            if attr.get("relation_kind") == relation and attr.get("target_class") == target:
                return attr
        return None

    def _set_many_to_many(
        self,
        normalized: Dict[str, Any],
        class_name: str,
        attr_name: str,
        target: str
    ) -> None:
        """Upgrades a one_to_many relation to many_to_many."""
        payload = normalized.get(class_name, {})
        for attr in payload.get("attributes", []):
            if attr.get("name") == attr_name:
                attr["relation_kind"] = "many_to_many"

    @staticmethod
    def _build_sdk_constraint(version: str) -> str:
        cleaned = version.strip()
        if cleaned.endswith(".x"):
            major, minor, _ = cleaned.split(".")
            next_minor = int(minor) + 1
            return f">={major}.{minor}.0 <{major}.{next_minor}.0"
        return f"^{cleaned}"


__all__ = ["DartCodeGenerator"]
