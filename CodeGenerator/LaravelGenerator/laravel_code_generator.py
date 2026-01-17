import json
import datetime
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

from jinja2 import Environment, FileSystemLoader


# Mapping UML types -> PHP types
PHP_TYPE_MAP = {
    "int": "int",
    "integer": "int",
    "long": "int",
    "float": "float",
    "double": "float",
    "decimal": "float",
    "bigdecimal": "float",
    "string": "string",
    "str": "string",
    "text": "string",
    "char": "string",
    "bool": "bool",
    "boolean": "bool",
    "uuid": "string",
    "localdate": "Carbon",
    "date": "Carbon",
    "localdatetime": "Carbon",
    "datetime": "Carbon",
    "time": "Carbon",
}

# Mapping PHP types -> Laravel migration column types
MIGRATION_TYPE_MAP = {
    "int": "integer",
    "float": "float",
    "string": "string",
    "bool": "boolean",
    "Carbon": "timestamp",
    "date": "date",
    "datetime": "datetime",
    "text": "text",
    "uuid": "uuid",
}

# Mapping PHP types -> Eloquent $casts
CAST_TYPE_MAP = {
    "int": "integer",
    "float": "float",
    "string": "string",
    "bool": "boolean",
    "Carbon": "datetime",
    "date": "date",
    "datetime": "datetime",
}


class LaravelCodeGenerator:
    """
    Generates a complete Laravel 12 project structure from normalized JSON.
    Includes Service layer, Repository pattern with interfaces, and full CRUD.
    """

    def __init__(self, output_root: Path | str | None = None, options: Dict[str, Any] | None = None) -> None:
        self.templates_dir = Path(__file__).resolve().parents[1] / "Templates" / "Laravel"
        self.static_dir = self.templates_dir / "static"
        self.output_root = Path(output_root or Path("GeneratedProject") / "Laravel")
        self.env = Environment(loader=FileSystemLoader(self.templates_dir))
        self.env.filters['snake_case'] = self._snake_case
        self.env.filters['plural'] = self._plural
        self.env.filters['camel_case'] = self._camel_case
        self.options = options or {}

    def generate_project(self, project_name: str, project_payload: Dict[str, Any]) -> Path:
        """Main entry point - generates complete Laravel project."""
        raw_classes = project_payload.get("classes", {})
        classes = self._normalize_classes(raw_classes)

        project_slug = self._slug(project_name)
        base_namespace = self._resolve_base_namespace()
        base_namespace_json = base_namespace.replace("\\", "\\\\")
        project_dir = self.output_root / project_slug

        # Create directory structure
        self._create_directory_structure(project_dir)

        # Copy static files
        self._copy_static_files(project_dir)
        self._patch_static_namespaces(project_dir, base_namespace)

        # Generate project-level files
        self._generate_project_files(
            project_dir,
            project_name,
            project_slug,
            classes,
            base_namespace,
            base_namespace_json,
        )

        # Generate class-specific files
        for class_name, class_payload in classes.items():
            self._generate_class_files(
                project_dir,
                class_name,
                class_payload,
                classes,
                base_namespace,
            )

        # Dump normalized JSON for reference
        self._dump_project_json(project_name, project_payload, project_dir)

        return project_dir

    def _create_directory_structure(self, project_dir: Path) -> None:
        """Creates the Laravel 12 directory structure."""
        directories = [
            # App directories
            "app/Http/Controllers",
            "app/Models",
            "app/Providers",
            "app/Repositories/Interfaces",
            "app/Services",
            # Bootstrap
            "bootstrap/cache",
            # Config
            "config",
            # Database
            "database/factories",
            "database/migrations",
            "database/seeders",
            # Public
            "public",
            # Resources
            "resources/css",
            "resources/js",
            "resources/views",
            # Routes
            "routes",
            # Storage
            "storage/app/private",
            "storage/app/public",
            "storage/framework/cache",
            "storage/framework/sessions",
            "storage/framework/testing",
            "storage/framework/views",
            "storage/logs",
            # Tests
            "tests/Feature",
            "tests/Unit",
        ]
        for directory in directories:
            (project_dir / directory).mkdir(parents=True, exist_ok=True)

    def _copy_static_files(self, project_dir: Path) -> None:
        """Copies static Laravel files from templates/static directory."""
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
        classes: Dict[str, Any],
        base_namespace: str,
        base_namespace_json: str,
    ) -> None:
        """Generates project-level files (routes, seeders, provider, composer, etc.)."""
        class_list = list(classes.keys())
        php_version = self.options.get("php_version", "8.2")
        laravel_version = self.options.get("laravel_version", "12.44.0")
        deps = set(self.options.get("deps", []) or [])
        include_pint = "laravel/pint" in deps
        db_connection = self.options.get("db", "mysql")
        queue_connection = self.options.get("queue", "database")
        cache_store = self.options.get("cache", "database")
        if queue_connection == "none":
            queue_connection = "sync"

        # Routes - web.php
        self._render_template(
            "project/web_routes.php.j2",
            project_dir / "routes" / "web.php",
            classes=class_list,
            base_namespace=base_namespace,
        )

        # Database seeder
        self._render_template(
            "project/database_seeder.php.j2",
            project_dir / "database" / "seeders" / "DatabaseSeeder.php",
            classes=class_list,
        )

        # App Service Provider with repository bindings
        self._render_template(
            "project/app_service_provider.php.j2",
            project_dir / "app" / "Providers" / "AppServiceProvider.php",
            classes=class_list,
            base_namespace=base_namespace,
        )

        # composer.json
        self._render_template(
            "project/composer.json.j2",
            project_dir / "composer.json",
            project_name=project_name,
            project_slug=project_slug,
            php_version=php_version,
            laravel_version=laravel_version,
            include_pint=include_pint,
            base_namespace=base_namespace,
            base_namespace_json=base_namespace_json,
        )

        # package.json
        self._render_template(
            "project/package.json.j2",
            project_dir / "package.json",
            project_name=project_name,
        )

        # .env and .env.example
        for env_file in [".env", ".env.example"]:
            self._render_template(
                "project/env.j2",
                project_dir / env_file,
                project_name=project_name,
                project_slug=project_slug,
                db_connection=db_connection,
                queue_connection=queue_connection,
                cache_store=cache_store,
            )

        # README.md
        self._render_template(
            "project/readme.md.j2",
            project_dir / "README.md",
            project_name=project_name,
            classes=class_list,
        )

    def _generate_class_files(
        self,
        project_dir: Path,
        class_name: str,
        class_payload: Dict[str, Any],
        all_classes: Dict[str, Any],
        base_namespace: str,
    ) -> None:
        """Generates all files for a single UML class."""
        attributes = class_payload.get("attributes", [])
        table_name = self._plural(self._snake_case(class_name))

        # Model
        self._render_template(
            "dynamic/model.php.j2",
            project_dir / "app" / "Models" / f"{class_name}.php",
            class_name=class_name,
            table_name=table_name,
            attributes=attributes,
            all_classes=all_classes,
            base_namespace=base_namespace,
        )

        # Controller
        self._render_template(
            "dynamic/controller.php.j2",
            project_dir / "app" / "Http" / "Controllers" / f"{class_name}Controller.php",
            class_name=class_name,
            base_namespace=base_namespace,
        )

        # Repository Interface
        self._render_template(
            "dynamic/repository_interface.php.j2",
            project_dir / "app" / "Repositories" / "Interfaces" / f"{class_name}RepositoryInterface.php",
            class_name=class_name,
            base_namespace=base_namespace,
        )

        # Repository Implementation
        self._render_template(
            "dynamic/repository.php.j2",
            project_dir / "app" / "Repositories" / f"{class_name}Repository.php",
            class_name=class_name,
            base_namespace=base_namespace,
        )

        # Service
        self._render_template(
            "dynamic/service.php.j2",
            project_dir / "app" / "Services" / f"{class_name}Service.php",
            class_name=class_name,
            base_namespace=base_namespace,
        )

        # Migration
        timestamp = self._generate_migration_timestamp(class_name)
        self._render_template(
            "dynamic/migration.php.j2",
            project_dir / "database" / "migrations" / f"{timestamp}_create_{table_name}_table.php",
            class_name=class_name,
            table_name=table_name,
            attributes=attributes,
        )

        # Factory
        self._render_template(
            "dynamic/factory.php.j2",
            project_dir / "database" / "factories" / f"{class_name}Factory.php",
            class_name=class_name,
            attributes=attributes,
            base_namespace=base_namespace,
        )

        # Seeder
        self._render_template(
            "dynamic/seeder.php.j2",
            project_dir / "database" / "seeders" / f"{class_name}Seeder.php",
            class_name=class_name,
            base_namespace=base_namespace,
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

                php_type = self._map_php_type(cleaned_type)
                migration_type = self._map_migration_type(php_type)
                cast_type = CAST_TYPE_MAP.get(php_type)

                is_primary = cleaned_name.lower() == "id"
                has_id = has_id or is_primary

                relation_kind = None
                target_class = None
                foreign_key = None
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
                    foreign_key = f"{self._snake_case(cleaned_name)}_id"
                    nullable = relation_hint != "composition"

                if is_primary:
                    nullable = False
                    php_type = "int"
                    migration_type = "id"

                attrs.append({
                    "name": cleaned_name,
                    "snake_name": self._snake_case(cleaned_name),
                    "type": php_type,
                    "migration_type": migration_type,
                    "cast_type": cast_type,
                    "nullable": nullable,
                    "is_primary": is_primary,
                    "relation_kind": relation_kind,
                    "relation_hint": relation_hint,
                    "target_class": target_class,
                    "foreign_key": foreign_key,
                    "join_table": None,
                    "cascade": relation_hint == "composition",
                })

            # Add id if missing
            if not has_id:
                attrs.insert(0, {
                    "name": "id",
                    "snake_name": "id",
                    "type": "int",
                    "migration_type": "id",
                    "cast_type": None,
                    "nullable": False,
                    "is_primary": True,
                    "relation_kind": None,
                    "relation_hint": None,
                    "target_class": None,
                    "foreign_key": None,
                    "join_table": None,
                    "cascade": False,
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

    def _resolve_base_namespace(self) -> str:
        raw = (self.options.get("package_name") or "").strip()
        if not raw:
            return "App"
        return self._sanitize_namespace(raw)

    def _sanitize_namespace(self, value: str) -> str:
        cleaned = value.replace("/", "\\").replace(".", "\\").strip("\\")
        parts = [p for p in re.split(r"\\\\+", cleaned) if p]
        normalized = []
        for part in parts:
            part = re.sub(r"[^A-Za-z0-9_]", "", part)
            if not part:
                continue
            if part[0].isdigit():
                part = f"Ns{part}"
            normalized.append(part[0].upper() + part[1:])
        return "\\".join(normalized) if normalized else "App"

    def _patch_static_namespaces(self, project_dir: Path, base_namespace: str) -> None:
        if base_namespace == "App":
            return
        controller_path = project_dir / "app" / "Http" / "Controllers" / "Controller.php"
        if not controller_path.exists():
            return
        content = controller_path.read_text(encoding="utf-8")
        content = content.replace(
            "namespace App\\Http\\Controllers;",
            f"namespace {base_namespace}\\Http\\Controllers;",
        )
        controller_path.write_text(content, encoding="utf-8")

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
        """Converts project name to slug (lowercase, alphanumeric, hyphens)."""
        return re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')

    def _snake_case(self, value: str) -> str:
        """Converts PascalCase/camelCase to snake_case."""
        if not value:
            return ""
        # Insert underscore before uppercase letters
        s1 = re.sub(r'(.)([A-Z][a-z]+)', r'\1_\2', value)
        return re.sub(r'([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

    def _camel_case(self, value: str) -> str:
        """Converts to camelCase."""
        if not value:
            return ""
        words = re.split(r'[_\s-]+', value)
        return words[0].lower() + ''.join(word.capitalize() for word in words[1:])

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
        # List<Something> / Set<Something>
        if "<" in cleaned and ">" in cleaned:
            return cleaned[cleaned.find("<") + 1:cleaned.rfind(">")] or None
        # Array syntax Something[]
        if cleaned.endswith("[]"):
            return cleaned[:-2] or None
        # Prefixed list/set
        lower = cleaned.lower()
        for prefix in ("listof", "setof"):
            if lower.startswith(prefix):
                return cleaned[len(prefix):]
        return None

    def _map_php_type(self, raw_type: str) -> str:
        """Maps UML type to PHP type."""
        lower = raw_type.lower()
        return PHP_TYPE_MAP.get(lower, "string")

    def _map_migration_type(self, php_type: str) -> str:
        """Maps PHP type to Laravel migration column type."""
        return MIGRATION_TYPE_MAP.get(php_type, "string")

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
        # Sort names for consistent join table naming
        names = sorted([self._snake_case(class_name), self._snake_case(target)])
        join_table = f"{names[0]}_{names[1]}"

        for attr in payload.get("attributes", []):
            if attr.get("name") == attr_name:
                attr["relation_kind"] = "many_to_many"
                attr["join_table"] = join_table

    def _generate_migration_timestamp(self, class_name: str) -> str:
        """Generates a unique timestamp for migration file."""
        # Use a base timestamp and add offset based on class name hash
        base = datetime.datetime(2025, 1, 1, 0, 0, 0)
        offset = abs(hash(class_name)) % 86400  # Max 1 day offset in seconds
        timestamp = base + datetime.timedelta(seconds=offset)
        return timestamp.strftime("%Y_%m_%d_%H%M%S")


__all__ = ["LaravelCodeGenerator"]
