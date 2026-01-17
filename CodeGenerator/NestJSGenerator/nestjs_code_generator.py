import json
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

from jinja2 import Environment, FileSystemLoader


# Mapping UML types -> TypeScript types
TS_TYPE_MAP = {
    "int": "number",
    "integer": "number",
    "long": "number",
    "float": "number",
    "double": "number",
    "decimal": "number",
    "bigdecimal": "number",
    "string": "string",
    "str": "string",
    "text": "string",
    "char": "string",
    "bool": "boolean",
    "boolean": "boolean",
    "uuid": "string",
    "localdate": "Date",
    "date": "Date",
    "localdatetime": "Date",
    "datetime": "Date",
    "time": "Date",
}

# Mapping TypeScript types -> TypeORM column types
TYPEORM_TYPE_MAP = {
    "number": "int",
    "string": "varchar",
    "boolean": "boolean",
    "Date": "timestamp",
    "text": "text",
    "uuid": "uuid",
}

# Mapping for class-validator decorators
VALIDATOR_MAP = {
    "number": "IsNumber",
    "string": "IsString",
    "boolean": "IsBoolean",
    "Date": "IsDate",
}


class NestJSCodeGenerator:
    """
    Generates a complete NestJS 11 project structure from normalized JSON.
    Includes TypeORM, Repository pattern, Service layer, DTOs with class-validator, and Swagger.
    """

    def __init__(self, output_root: Path | str | None = None, options: Dict[str, Any] | None = None) -> None:
        self.templates_dir = Path(__file__).resolve().parents[1] / "Templates" / "NestJS"
        self.static_dir = self.templates_dir / "static"
        self.output_root = Path(output_root or Path("GeneratedProject") / "NestJS")
        self.env = Environment(loader=FileSystemLoader(self.templates_dir))
        self.env.filters['snake_case'] = self._snake_case
        self.env.filters['plural'] = self._plural
        self.env.filters['camel_case'] = self._camel_case
        self.env.filters['kebab_case'] = self._kebab_case
        self.env.filters['pascal_case'] = self._pascal_case
        self.options = options or {}

    def generate_project(self, project_name: str, project_payload: Dict[str, Any]) -> Path:
        """Main entry point - generates complete NestJS project."""
        raw_classes = project_payload.get("classes", {})
        classes = self._normalize_classes(raw_classes)

        project_slug = self._slug(project_name)
        npm_name = self._resolve_npm_name(project_slug)
        project_dir = self.output_root / project_slug

        # Create directory structure
        self._create_directory_structure(project_dir, classes)

        # Copy static files
        self._copy_static_files(project_dir)

        # Generate project-level files
        self._generate_project_files(
            project_dir,
            project_name,
            project_slug,
            classes,
            npm_name,
        )

        # Generate class-specific files (module per entity)
        for class_name, class_payload in classes.items():
            self._generate_class_files(project_dir, class_name, class_payload, classes)

        # Dump normalized JSON for reference
        self._dump_project_json(project_name, project_payload, project_dir)

        return project_dir

    def _create_directory_structure(self, project_dir: Path, classes: Dict[str, Any]) -> None:
        """Creates the NestJS 11 directory structure."""
        directories = [
            # Source directories
            "src/common/decorators",
            "src/common/filters",
            "src/common/guards",
            "src/common/interceptors",
            "src/common/pipes",
            "src/config",
            "src/database",
            # Test directories
            "test",
        ]

        # Add module directories for each entity
        for class_name in classes.keys():
            module_name = self._kebab_case(class_name)
            directories.extend([
                f"src/{module_name}/dto",
                f"src/{module_name}/entities",
                f"src/{module_name}/repositories",
            ])

        for directory in directories:
            (project_dir / directory).mkdir(parents=True, exist_ok=True)

    def _copy_static_files(self, project_dir: Path) -> None:
        """Copies static NestJS files from templates/static directory."""
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
        npm_name: str,
    ) -> None:
        """Generates project-level files (main.ts, app.module.ts, configs, etc.)."""
        class_list = list(classes.keys())
        db_type = self.options.get("db", "postgres")
        node_version = self.options.get("node_version", "20")
        nest_version = self.options.get("nest_version", "11.1.x")
        nest_dependency_version = self._dependency_version(nest_version)

        # main.ts with Swagger setup
        self._render_template(
            "project/main.ts.j2",
            project_dir / "src" / "main.ts",
            project_name=project_name,
        )

        # app.module.ts
        self._render_template(
            "project/app.module.ts.j2",
            project_dir / "src" / "app.module.ts",
            classes=class_list,
        )

        # app.controller.ts
        self._render_template(
            "project/app.controller.ts.j2",
            project_dir / "src" / "app.controller.ts",
        )

        # app.service.ts
        self._render_template(
            "project/app.service.ts.j2",
            project_dir / "src" / "app.service.ts",
        )

        # Database configuration
        self._render_template(
            "project/database.config.ts.j2",
            project_dir / "src" / "config" / "database.config.ts",
        )

        # TypeORM data source
        self._render_template(
            "project/data-source.ts.j2",
            project_dir / "src" / "database" / "data-source.ts",
            classes=class_list,
        )

        # package.json
        self._render_template(
            "project/package.json.j2",
            project_dir / "package.json",
            project_name=project_name,
            project_slug=project_slug,
            npm_name=npm_name,
            nest_version=nest_version,
            nest_dependency_version=nest_dependency_version,
        )

        # tsconfig.json
        self._render_template(
            "project/tsconfig.json.j2",
            project_dir / "tsconfig.json",
        )

        # tsconfig.build.json
        self._render_template(
            "project/tsconfig.build.json.j2",
            project_dir / "tsconfig.build.json",
        )

        # nest-cli.json
        self._render_template(
            "project/nest-cli.json.j2",
            project_dir / "nest-cli.json",
        )

        # .env and .env.example
        for env_file in [".env", ".env.example"]:
            self._render_template(
                "project/env.j2",
                project_dir / env_file,
                project_name=project_name,
                project_slug=project_slug,
                db_type=db_type,
            )

        # README.md
        self._render_template(
            "project/readme.md.j2",
            project_dir / "README.md",
            project_name=project_name,
            classes=class_list,
            db_type=db_type,
            node_version=node_version,
            nest_version=nest_version,
        )

        # Common exception filter
        self._render_template(
            "project/http-exception.filter.ts.j2",
            project_dir / "src" / "common" / "filters" / "http-exception.filter.ts",
        )

        # Validation pipe config
        self._render_template(
            "project/validation.pipe.ts.j2",
            project_dir / "src" / "common" / "pipes" / "validation.pipe.ts",
        )

    def _generate_class_files(
        self,
        project_dir: Path,
        class_name: str,
        class_payload: Dict[str, Any],
        all_classes: Dict[str, Any],
    ) -> None:
        """Generates all files for a single entity module."""
        attributes = class_payload.get("attributes", [])
        module_name = self._kebab_case(class_name)
        table_name = self._plural(self._snake_case(class_name))

        module_dir = project_dir / "src" / module_name

        # Entity
        self._render_template(
            "dynamic/entity.ts.j2",
            module_dir / "entities" / f"{module_name}.entity.ts",
            class_name=class_name,
            table_name=table_name,
            attributes=attributes,
            all_classes=all_classes,
        )

        # Repository Interface
        self._render_template(
            "dynamic/repository.interface.ts.j2",
            module_dir / "repositories" / f"{module_name}.repository.interface.ts",
            class_name=class_name,
        )

        # Repository Implementation
        self._render_template(
            "dynamic/repository.ts.j2",
            module_dir / "repositories" / f"{module_name}.repository.ts",
            class_name=class_name,
            module_name=module_name,
        )

        # DTOs - Create
        self._render_template(
            "dynamic/create.dto.ts.j2",
            module_dir / "dto" / f"create-{module_name}.dto.ts",
            class_name=class_name,
            attributes=attributes,
            all_classes=all_classes,
        )

        # DTOs - Update
        self._render_template(
            "dynamic/update.dto.ts.j2",
            module_dir / "dto" / f"update-{module_name}.dto.ts",
            class_name=class_name,
            module_name=module_name,
        )

        # Service
        self._render_template(
            "dynamic/service.ts.j2",
            module_dir / f"{module_name}.service.ts",
            class_name=class_name,
            module_name=module_name,
        )

        # Controller
        self._render_template(
            "dynamic/controller.ts.j2",
            module_dir / f"{module_name}.controller.ts",
            class_name=class_name,
            module_name=module_name,
        )

        # Module
        self._render_template(
            "dynamic/module.ts.j2",
            module_dir / f"{module_name}.module.ts",
            class_name=class_name,
            module_name=module_name,
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

                ts_type = self._map_ts_type(cleaned_type)
                typeorm_type = self._map_typeorm_type(ts_type)
                validator = VALIDATOR_MAP.get(ts_type)

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
                    foreign_key = f"{self._camel_case(cleaned_name)}Id"
                    nullable = relation_hint != "composition"

                if is_primary:
                    nullable = False
                    ts_type = "number"
                    typeorm_type = "int"

                attrs.append({
                    "name": cleaned_name,
                    "camel_name": self._camel_case(cleaned_name),
                    "type": ts_type,
                    "typeorm_type": typeorm_type,
                    "validator": validator,
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
                    "camel_name": "id",
                    "type": "number",
                    "typeorm_type": "int",
                    "validator": "IsNumber",
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

    def _resolve_npm_name(self, fallback: str) -> str:
        raw = (self.options.get("package_name") or "").strip()
        if not raw:
            return fallback
        cleaned = raw.lower().replace(" ", "-")
        if cleaned.startswith("@"):
            if "/" not in cleaned:
                return fallback
            scope, name = cleaned.split("/", 1)
            scope = re.sub(r"[^a-z0-9-_@]", "", scope)
            name = re.sub(r"[^a-z0-9-_.]", "-", name)
            name = re.sub(r"-+", "-", name).strip("-")
            if not name or scope == "@":
                return fallback
            return f"{scope}/{name}"
        name = re.sub(r"[^a-z0-9-_.]", "-", cleaned)
        name = re.sub(r"-+", "-", name).strip("-")
        return name or fallback

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
        words = re.split(r'[_\s-]+', value)
        return words[0].lower() + ''.join(word.capitalize() for word in words[1:])

    def _pascal_case(self, value: str) -> str:
        """Converts to PascalCase."""
        if not value:
            return ""
        words = re.split(r'[_\s-]+', value)
        return ''.join(word.capitalize() for word in words)

    def _kebab_case(self, value: str) -> str:
        """Converts to kebab-case."""
        if not value:
            return ""
        s1 = re.sub(r'(.)([A-Z][a-z]+)', r'\1-\2', value)
        return re.sub(r'([a-z0-9])([A-Z])', r'\1-\2', s1).lower()

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

    def _map_ts_type(self, raw_type: str) -> str:
        """Maps UML type to TypeScript type."""
        lower = raw_type.lower()
        return TS_TYPE_MAP.get(lower, "string")

    def _map_typeorm_type(self, ts_type: str) -> str:
        """Maps TypeScript type to TypeORM column type."""
        return TYPEORM_TYPE_MAP.get(ts_type, "varchar")

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
        names = sorted([self._snake_case(class_name), self._snake_case(target)])
        join_table = f"{names[0]}_{names[1]}"

        for attr in payload.get("attributes", []):
            if attr.get("name") == attr_name:
                attr["relation_kind"] = "many_to_many"
                attr["join_table"] = join_table

    @staticmethod
    def _dependency_version(version: str) -> str:
        cleaned = version.strip()
        if "x" in cleaned:
            return cleaned
        return f"^{cleaned}"


__all__ = ["NestJSCodeGenerator"]
