import json
import re
from pathlib import Path
from typing import Any, Dict

from jinja2 import Environment, FileSystemLoader

from CodeGenerator.Templates.Spring.test_applicationProperties import (
    generate_application_properties,
)

from helpers.utils import Utils


class SpringCodeGenerator:
    """
    Orchestrateur unique pour la génération du code Spring à partir du JSON normalisé.
    Reprend la structure Maven décrite dans project_structure_generated.sh et génère un pom.xml.
    """

    def __init__(
        self,
        output_root: Path | str | None = None,
        group_id: str | None = None,
        version: str = "1.0-SNAPSHOT",
        spring_boot_version: str = "4.0.1",
        java_version: str = "21",
        db: str = "mysql",
        dependencies: list[str] | None = None,
        tests: str = "junit",
    ) -> None:
        templates_dir = Path(__file__).resolve().parents[1] / "Templates" / "Spring"
        self.output_root = Path(output_root or Path("GeneratedProject") / "Spring")
        self.controller_template = templates_dir / "controller.java.j2"
        self.repository_template = templates_dir / "repository.java.j2"
        self.app_properties_template = templates_dir / "application.properties.html"
        self.service_template = templates_dir / "service.java.j2"
        self.dto_template = templates_dir / "dto.java.j2"
        self.model_template = templates_dir / "Model.jinja"
        self.exception_template = templates_dir / "exception.java.j2"
        self.exception_handler_template = templates_dir / "exception_handler.java.j2"
        self.test_template = templates_dir / "test_main.java.j2"
        self.application_template = templates_dir / "fichierapp.java.j2"
        self.env = Environment(loader=FileSystemLoader(templates_dir))
        self.group_id = group_id or ""
        self.version = version
        self.spring_boot_version = self._normalize_semver(spring_boot_version)
        self.java_version = java_version
        self.db = (db or "mysql").lower()
        self.dependencies = dependencies or []
        self.tests = tests

    @staticmethod
    def _normalize_semver(version: str) -> str:
        cleaned = version.strip()
        if cleaned.startswith("~"):
            cleaned = cleaned[1:]
        if cleaned.endswith(".x"):
            return f"{cleaned[:-2]}.0"
        return cleaned

    def generate_project(self, project_name: str, project_payload: Dict[str, Any]) -> None:
        raw_classes = project_payload.get("classes", {})
        classes = self._normalize_classes(raw_classes)
        base_package = self._resolve_base_package(project_name)
        package_path = Path(*base_package.split("."))
        project_dir = self.output_root / project_name

        java_root = project_dir / "src" / "main" / "java" / package_path
        controllers_dir = java_root / "controller"
        repositories_dir = java_root / "repository"
        resources_dir = project_dir / "src" / "main" / "resources"
        test_java_dir = project_dir / "src" / "test" / "java" / package_path
        test_resources_dir = project_dir / "src" / "test" / "resources"

        for path in (
            controllers_dir,
            repositories_dir,
            java_root / "dto",
            java_root / "entity",
            java_root / "service",
            java_root / "configs",
            java_root / "enums",
            java_root / "exception",
            resources_dir,
            test_java_dir,
            test_resources_dir,
        ):
            self._ensure_dir(path)

        main_class_name = self._pascal_case(project_name)
        self._render_template(
            self.application_template,
            java_root / f"{main_class_name}Application.java",
            base_package=base_package,
            class_name=main_class_name,
        )

        self._write_pom(project_dir, artifact_id=project_name, group_id=base_package)

        generate_application_properties(
            resources_dir,
            classes,
            app_name=project_name,
            db=self.db,
            template_path=self.app_properties_template,
        )

        for class_name, class_payload in classes.items():
            self._render_template(
                self.controller_template,
                controllers_dir / f"{class_name}Controller.java",
                base_package=base_package,
                class_name=class_name,
            )
            self._render_model_template(
                self.model_template,
                java_root / "entity" / f"{class_name}.java",
                base_package,
                class_payload,
                classes,
            )
            self._render_template(
                self.repository_template,
                java_root / "repository" / f"{class_name}Repository.java",
                base_package=base_package,
                class_name=class_name,
            )
            self._render_class_template(
                self.service_template,
                java_root / "service" / f"{class_name}Service.java",
                base_package,
                class_name,
                class_payload,
            )
            self._render_class_template(
                self.dto_template,
                java_root / "dto" / f"{class_name}DTO.java",
                base_package,
                class_name,
                class_payload,
            )
            self._render_class_template(
                self.exception_template,
                java_root / "exceptions" / f"{class_name}NotFoundException.java",
                base_package,
                class_name,
                class_payload,
            )
        # Global exception handler
        self._render_template(
            self.exception_handler_template,
            java_root / "exceptions" / "GlobalExceptionHandler.java",
            base_package=base_package,
        )

        self._dump_project_json(project_name, project_payload, project_dir)
        # Test de base
        self._render_template(
            self.test_template,
            test_java_dir / f"{project_name}ApplicationTests.java",
            base_package=base_package,
            project_name=project_name,
        )

    def _write_pom(self, project_dir: Path, artifact_id: str, group_id: str) -> Path:
        dependencies = []
        required = [
            ("org.springframework.boot", "spring-boot-starter-web"),
            ("org.springframework.boot", "spring-boot-starter-data-jpa"),
            ("org.springframework.boot", "spring-boot-starter-validation"),
        ]
        for group_id, artifact_id in required:
            dependencies.append(self._dependency_xml(group_id, artifact_id))

        optional_map = {
            "security": ("org.springframework.boot", "spring-boot-starter-security", None),
            "actuator": ("org.springframework.boot", "spring-boot-starter-actuator", None),
            "devtools": ("org.springframework.boot", "spring-boot-devtools", "runtime"),
        }
        for key, (group_id, artifact_id, scope) in optional_map.items():
            if key in self.dependencies:
                dependencies.append(self._dependency_xml(group_id, artifact_id, scope=scope))

        if "lombok" in self.dependencies:
            dependencies.append(
                self._dependency_xml(
                    "org.projectlombok",
                    "lombok",
                    version="${lombok.version}",
                    scope="provided",
                )
            )

        db_dependency = self._db_dependency()
        if db_dependency:
            dependencies.append(self._dependency_xml(*db_dependency))

        if self.tests == "junit":
            dependencies.append(
                self._dependency_xml(
                    "org.springframework.boot",
                    "spring-boot-starter-test",
                    scope="test",
                )
            )

        dependencies_block = "\n".join(dependencies)
        pom_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>{self.spring_boot_version}</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>

    <groupId>{group_id}</groupId>
    <artifactId>{artifact_id}</artifactId>
    <version>{self.version}</version>
    <name>{artifact_id}</name>

    <properties>
        <java.version>{self.java_version}</java.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <lombok.version>1.18.30</lombok.version>
    </properties>

    <dependencies>
{dependencies_block}
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
"""
        pom_path = project_dir / "pom.xml"
        self._ensure_dir(project_dir)
        pom_path.write_text(pom_content, encoding="utf-8")
        return pom_path

    def _dependency_xml(
        self,
        group_id: str,
        artifact_id: str,
        version: str | None = None,
        scope: str | None = None,
    ) -> str:
        lines = [
            "        <dependency>",
            f"            <groupId>{group_id}</groupId>",
            f"            <artifactId>{artifact_id}</artifactId>",
        ]
        if version:
            lines.append(f"            <version>{version}</version>")
        if scope:
            lines.append(f"            <scope>{scope}</scope>")
        lines.append("        </dependency>")
        return "\n".join(lines)

    def _db_dependency(self) -> tuple[str, str, str | None, str | None] | None:
        db_map = {
            "mysql": ("com.mysql", "mysql-connector-j", None, "runtime"),
            "postgres": ("org.postgresql", "postgresql", None, "runtime"),
            "mariadb": ("org.mariadb.jdbc", "mariadb-java-client", None, "runtime"),
            "h2": ("com.h2database", "h2", None, "runtime"),
        }
        return db_map.get(self.db)

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

    def _slugify(self, name: str) -> str:
        return "".join(ch for ch in name if ch.isalnum()).lower()

    def _pascal_case(self, value: str) -> str:
        if not isinstance(value, str):
            return "Application"
        parts = [part for part in re.split(r"[^0-9A-Za-z]+", value) if part]
        if not parts:
            return "Application"
        return "".join(part.capitalize() for part in parts)

    def _render_template(self, template_path: Path, output_path: Path, **context: Any) -> None:
        template = self.env.get_template(template_path.name)
        rendered = template.render(**context)
        self._ensure_dir(output_path.parent)
        output_path.write_text(rendered, encoding="utf-8")

    def _render_class_template(
        self,
        template_path: Path,
        output_path: Path,
        base_package: str,
        class_name: str,
        class_payload: Dict[str, Any],
    ) -> None:
        attributes = class_payload.get("attributes", [])
        self._render_template(
            template_path,
            output_path,
            base_package=base_package,
            class_name=class_name,
            attributes=attributes,
        )

    def _render_model_template(
        self,
        template_path: Path,
        output_path: Path,
        base_package: str,
        class_payload: Dict[str, Any],
        classes: Dict[str, Any],
    ) -> None:
        self._render_template(
            template_path,
            output_path,
            base_package=base_package,
            data=class_payload,
            classes=classes,
        )

    def _resolve_base_package(self, project_name: str) -> str:
        raw = (self.group_id or "").strip()
        if not raw:
            raw = f"com.example.{self._slugify(project_name)}"
        return self._sanitize_package(raw)

    @staticmethod
    def _sanitize_package(value: str) -> str:
        if not value:
            return "com.example"

        cleaned = re.sub(r"[^A-Za-z0-9_.]", ".", value.strip())
        cleaned = re.sub(r"\.+", ".", cleaned).strip(".")
        if not cleaned:
            return "com.example"

        parts = []
        for part in cleaned.split("."):
            part = re.sub(r"[^A-Za-z0-9_]", "_", part).lower()
            if not part:
                continue
            if not re.match(r"^[a-z_]", part):
                part = f"pkg_{part}"
            parts.append(part)

        return ".".join(parts) if parts else "com.example"

    def _normalize_classes(self, classes: Dict[str, Any]) -> Dict[str, Any]:
        """Nettoie les attributs et infère les relations (hints $/#, collections → one-to-many, réciproques → many-to-many)."""
        class_names = set(classes.keys())
        normalized: Dict[str, Any] = {}
        pending_relations = []
        for class_name, payload in classes.items():
            attrs = []
            has_id = False
            type_descriptor = Utils.parse_class_descriptor(payload.get("type"))
            for attr in payload.get("attributes", []):
                raw_name = attr.get("attribute_name") or attr.get("name") or ""
                raw_type = attr.get("attribute_type") or attr.get("type") or "String"
                relation_hint = self._relation_hint(raw_name, raw_type)

                cleaned_name = self._clean_name(raw_name)
                cleaned_type = self._clean_type(raw_type)
                collection_of = self._extract_collection_type(cleaned_type)
                java_type = self._map_java_type(cleaned_type)

                target_class = None
                relation = None
                join_column = None
                nullable = True
                join_table = None

                # Collection -> one-to-many candidate
                if collection_of and collection_of in class_names:
                    target_class = collection_of
                    relation = "one_to_many"
                    java_type = f"List<{target_class}>"
                    nullable = relation_hint != "composition"
                elif cleaned_type in class_names:
                    target_class = cleaned_type
                    relation = "many_to_one"
                    java_type = target_class
                    join_column = f"{cleaned_name}_id"
                    nullable = relation_hint != "composition"

                is_id = cleaned_name == "id"
                has_id = has_id or is_id
                if is_id:
                    java_type = "Long"
                    cleaned_type = "Long"
                    nullable = False

                attrs.append(
                    {
                        "attribute_name": cleaned_name,
                        "attribute_type": java_type,
                        "raw_type": cleaned_type,
                        "collection_of": collection_of,
                        "visibility": attr.get("visibility", "private"),
                        "relation": relation,
                        "relation_hint": relation_hint,
                        "target_class": target_class,
                        "join_column": join_column,
                        "inverse_join_column": None,
                        "is_id": is_id,
                        "nullable": nullable,
                        "cascade_all": relation_hint == "composition",
                        "join_table": join_table,
                    }
                )
                if relation == "one_to_many":
                    pending_relations.append((class_name, cleaned_name, target_class))

            if not has_id:
                attrs.insert(
                    0,
                    {
                        "attribute_name": "id",
                        "attribute_type": "Long",
                        "raw_type": "Long",
                        "collection_of": None,
                        "visibility": "public",
                        "relation": None,
                        "relation_hint": None,
                        "target_class": None,
                        "join_column": None,
                        "inverse_join_column": None,
                        "is_id": True,
                        "nullable": False,
                        "cascade_all": False,
                        "join_table": None,
                    },
                )

            new_payload = payload.copy()
            new_payload["attributes"] = attrs
            new_payload["class_type"] = type_descriptor.get("class_type")
            new_payload["extends"] = type_descriptor.get("extends")
            new_payload["implements"] = type_descriptor.get("implements")
            new_payload["original_name"] = payload.get("name") or class_name
            normalized[class_name] = new_payload

        # Upgrade mutual one-to-many to many-to-many
        for owner, attr_name, target in pending_relations:
            reverse = self._find_relation(normalized, target, owner, relation="one_to_many")
            if reverse:
                self._set_many_to_many(normalized, owner, attr_name, target)
                self._set_many_to_many(normalized, target, reverse["attribute_name"], owner)
        return normalized

    def _clean_name(self, value: str) -> str:
        return value.replace(" ", "").replace("$", "").replace("#", "")

    def _clean_type(self, value: str) -> str:
        return value.replace("$", "").replace("#", "").strip()

    def _relation_hint(self, raw_name: str, raw_type: str) -> str | None:
        if "$" in raw_name or "$" in raw_type:
            return "composition"
        if "#" in raw_name or "#" in raw_type:
            return "aggregation"
        return None

    def _extract_collection_type(self, raw_type: str) -> str | None:
        """Renvoie le type élémentaire si la chaîne ressemble à une collection."""
        if not raw_type:
            return None
        cleaned = raw_type.replace(" ", "")
        # List<Something> / Set<Something>
        if "<" in cleaned and ">" in cleaned:
            inner = cleaned[cleaned.find("<") + 1 : cleaned.rfind(">")]
            return inner or None
        # Array syntax Something[]
        if cleaned.endswith("[]"):
            return cleaned[:-2] or None
        # Prefixed list/set
        lowered = cleaned.lower()
        for prefix in ("listof", "setof"):
            if lowered.startswith(prefix):
                return cleaned[len(prefix) :]
        return None

    def _map_java_type(self, raw_type: str) -> str:
        mapping = {
            "int": "Integer",
            "integer": "Integer",
            "long": "Long",
            "float": "Double",
            "double": "Double",
            "decimal": "BigDecimal",
            "bigdecimal": "BigDecimal",
            "bool": "Boolean",
            "boolean": "Boolean",
            "string": "String",
            "str": "String",
            "localdate": "LocalDate",
            "date": "LocalDate",
            "localdatetime": "LocalDateTime",
            "datetime": "LocalDateTime",
            "time": "LocalTime",
            "uuid": "UUID",
        }
        lower = raw_type.lower()
        return mapping.get(lower, raw_type)

    def _find_relation(self, normalized: Dict[str, Any], class_name: str, target: str, relation: str) -> Dict[str, Any] | None:
        payload = normalized.get(class_name, {})
        for attr in payload.get("attributes", []):
            if attr.get("relation") == relation and attr.get("target_class") == target:
                return attr
        return None

    def _set_many_to_many(self, normalized: Dict[str, Any], class_name: str, attr_name: str, target: str) -> None:
        payload = normalized.get(class_name, {})
        for attr in payload.get("attributes", []):
            if attr.get("attribute_name") == attr_name:
                attr["relation"] = "many_to_many"
                attr["attribute_type"] = f"Set<{target}>"
                attr["join_table"] = f"{class_name.lower()}_{target.lower()}"
                attr["join_column"] = f"{class_name.lower()}_id"
                attr["inverse_join_column"] = f"{target.lower()}_id"


__all__ = ["SpringCodeGenerator"]
