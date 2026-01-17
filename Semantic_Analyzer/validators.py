from __future__ import annotations

from difflib import get_close_matches
from typing import Dict, Iterable, List, Optional, Tuple

_LANGUAGE_CANONICAL_TYPES: Dict[str, Dict[str, str]] = {
    "java": {
        "boolean": "Boolean",
        "bolean": "Boolean",
        "bool": "Boolean",
        "bol": "Boolean",
        "byte": "Byte",
        "short": "Short",
        "int": "Integer",
        "integer": "Integer",
        "in": "Integer",
        "long": "Long",
        "float": "Float",
        "double": "Double",
        "doubl": "Double",
        "char": "Character",
        "character": "Character",
        "void": "void",
        "object": "Object",
        "string": "String",
        "str": "String",
        "strin": "String",
        "sting": "String",
        "text": "String",
        # temporal types
        "date": "LocalDate",
        "localdate": "LocalDate",
        "datetime": "LocalDateTime",
        "localdatetime": "LocalDateTime",
        "timestamp": "Instant",
        # collections
        "list": "List",
        "arraylist": "List",
        "set": "Set",
        "hashset": "Set",
        "map": "Map",
        "hashmap": "Map",
        # numeric variants and short-hands
        "number": "BigDecimal",
        "decimal": "BigDecimal",
        "bigdecimal": "BigDecimal",
        "doubleprecision": "Double",
        "longint": "Long",
        "shortint": "Short",
    },
    "php": {
        "int": "int",
        "integer": "int",
        "long": "int",
        "short": "int",
        "float": "float",
        "double": "float",
        "decimal": "float",
        "string": "string",
        "str": "string",
        "text": "string",
        "char": "string",
        "bool": "bool",
        "boolean": "bool",
        "array": "array",
        "list": "array",
        "dict": "array",
        "map": "array",
        "callable": "callable",
        "closure": "callable",
        "iterable": "iterable",
        "object": "object",
        "mixed": "mixed",
        "void": "void",
        "resource": "resource",
        "datetime": "DateTime",
    },
    "python": {
        "int": "int",
        "integer": "int",
        "long": "int",
        "float": "float",
        "double": "float",
        "decimal": "Decimal",
        "str": "str",
        "string": "str",
        "text": "str",
        "char": "str",
        "bool": "bool",
        "boolean": "bool",
        "list": "list",
        "array": "list",
        "tuple": "tuple",
        "set": "set",
        "frozenset": "frozenset",
        "dict": "dict",
        "map": "dict",
        "object": "object",
        "any": "typing.Any",
        "callable": "typing.Callable",
        "iterable": "typing.Iterable",
        "generator": "typing.Generator",
        "datetime": "datetime.datetime",
        "date": "datetime.date",
        "time": "datetime.time",
        "timedelta": "datetime.timedelta",
        "bytes": "bytes",
        "bytearray": "bytearray",
        "memoryview": "memoryview",
        "none": "None",
        "nonetype": "None",
    },
}

from models.class_model import Class


class SemanticValidator:
    """
    Utilitaires deterministes de normalisation des types avec mappings internes / Deterministic type normalisation utilities relying on curated mappings.
    """

    def __init__(self, language: str = "java"):
        """Stocke le langage cible pour choisir la bonne table canonique / Stores the target language so lookups use the proper canonical map."""
        self.language = language

    def normalize_type(
        self,
        raw_type: str,
        known_types: Optional[Iterable[str]] = None,
        known_lookup: Optional[Dict[str, str]] = None,
    ) -> str:
        """Renvoie la forme canonique de la chaine de type fournie / Returns the canonical form of the provided type string."""
        if not raw_type:
            return raw_type

        type_name = raw_type.strip()
        if not type_name:
            return raw_type

        canonical_map = _LANGUAGE_CANONICAL_TYPES.get(self.language.lower(), {})
        if known_lookup is None:
            known_lookup = {name.lower(): name for name in known_types or []}

        array_suffix = ""
        while type_name.endswith("[]"):
            array_suffix += "[]"
            type_name = type_name[:-2].strip()

        generic_parts = self._extract_generic(type_name)
        if generic_parts:
            base, arguments = generic_parts
            normalized_base = self._normalize_atomic(
                base, canonical_map, known_lookup)
            normalized_args = [
                self.normalize_type(
                    arg,
                    known_types=None,
                    known_lookup=known_lookup,
                )
                for arg in arguments
            ]
            generic_repr = f"{normalized_base}<{', '.join(normalized_args)}>"
            return f"{generic_repr}{array_suffix}"

        normalized = self._normalize_atomic(type_name, canonical_map, known_lookup)
        return f"{normalized}{array_suffix}"

    def verify_types(
        self,
        classes: List[Class],
        known_types: Optional[Iterable[str]] = None,
    ) -> List[Class]:
        """
        Normalise attributs, retours de methode, arguments et relations sans service externe / Normalises attribute, method return, argument and relationship types without external services.
        """
        combined_known = set(known_types or [])
        combined_known.update(
            _class.name for _class in classes if getattr(_class, "name", None)
        )

        known_lookup = {name.lower(): name for name in combined_known if name}
        cache: Dict[str, str] = {}

        def normalise(value: Optional[str]) -> Optional[str]:
            """Canonicalise une valeur de type brute via un cache partage / Canonicalises a raw type value leveraging a shared cache."""
            if value is None:
                return value
            stripped = value.strip()
            if not stripped:
                return value
            cache_key = stripped.lower()
            cached = cache.get(cache_key)
            if cached is not None:
                return cached
            canonical = self.normalize_type(
                stripped,
                known_types=None,
                known_lookup=known_lookup,
            )
            cache[cache_key] = canonical
            return canonical

        for _class in classes:
            for attrib in getattr(_class, "attributes", []):
                attrib._type = normalise(getattr(attrib, "_type", None))

            for attrib in getattr(_class, "aggregations", []):
                attrib._type = normalise(getattr(attrib, "_type", None))

            for attrib in getattr(_class, "compositions", []):
                attrib._type = normalise(getattr(attrib, "_type", None))

            for method in getattr(_class, "methods", []):
                method._type = normalise(getattr(method, "_type", None))
                for arg in getattr(method, "args", []):
                    arg._type = normalise(getattr(arg, "_type", None))

        return classes

    def _normalize_atomic(
        self,
        token: str,
        canonical_map: Dict[str, str],
        known_lookup: Dict[str, str],
    ) -> str:
        """Resout un token non generique via les tables canoniques et connues / Resolves a single non generic token against canonical and user types."""
        lowered = token.lower()

        if lowered in canonical_map:
            return canonical_map[lowered]

        if lowered in known_lookup:
            return known_lookup[lowered]

        candidates = list(canonical_map.keys()) + list(known_lookup.keys())
        if candidates:
            matches = get_close_matches(lowered, candidates, n=1, cutoff=0.6)
            if matches:
                match_key = matches[0]
                if match_key in canonical_map:
                    return canonical_map[match_key]
                return known_lookup[match_key]

        return token[:1].upper() + token[1:] if token else token

    def _extract_generic(self, type_name: str) -> Optional[Tuple[str, List[str]]]:
        """Decoupe `Foo<Bar, Baz>` en base et liste d arguments / Splits `Foo<Bar, Baz>` into base part and raw arguments."""
        start = type_name.find("<")
        end = type_name.rfind(">")
        if start == -1 or end == -1 or end < start:
            return None

        base = type_name[:start].strip()
        args_segment = type_name[start + 1 : end]
        arguments = self._split_generic_arguments(args_segment)
        return base, arguments

    def _split_generic_arguments(self, payload: str) -> List[str]:
        """Analyse les arguments generiques separes par des virgules en gerant l imbrication / Parses comma separated generic arguments while handling nesting."""
        arguments: List[str] = []
        buffer: List[str] = []
        depth = 0

        for char in payload:
            if char == "<":
                depth += 1
            elif char == ">":
                depth = max(0, depth - 1)
            elif char == "," and depth == 0:
                argument = "".join(buffer).strip()
                if argument:
                    arguments.append(argument)
                buffer = []
                continue

            buffer.append(char)

        argument = "".join(buffer).strip()
        if argument:
            arguments.append(argument)

        return arguments
