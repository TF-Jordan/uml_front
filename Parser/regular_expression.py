import re
import html
from typing import Tuple, List, Dict


class RegularExpression:

    @staticmethod
    def parse_attribute_value(value: str) -> Tuple[str, str, str]:
        if not isinstance(value, str):
            return "+", "attribute", "Object"
        if not value.strip():
            return "+", "attribute", "Object"
        pattern = r'(?P<visibility>[+#-])\s*(?P<name>[a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*(?P<type>[a-zA-Z_][a-zA-Z0-9_]*)'
        match = re.match(pattern, value)
        if match:
            return match.group("visibility"), match.group("name"), match.group("type")
        return "+", value.strip() or "attribute", "Object"

    @staticmethod
    def parse_method_value(value: str) -> Tuple[str, str, str, List[str]]:
        if not isinstance(value, str):
            return "+", "method", "void", []
        if not value.strip():
            return "+", "method", "void", []
        pattern = r'(?P<visibility>[+#-])\s*(?P<name>[a-zA-Z_][a-zA-Z0-9_]*)\s*\((?P<args>[a-zA-Z0-9_,\s]*)\)\s*:\s*(?P<type>[a-zA-Z_][a-zA-Z0-9_]*)'
        match = re.match(pattern, value)
        if match:
            args = [arg.strip() for arg in match.group(
                "args").split(",") if arg.strip()]
            return match.group("visibility"), match.group("name"), match.group("type"), args
        return "+", value.strip() or "method", "void", []

    @staticmethod
    def split_members(value: str) -> List[str]:
        """
        Nettoie une valeur HTML provenant de draw.io et isole chaque attribut ou
        méthode éventuellement regroupés dans la même cellule.
        """
        if not isinstance(value, str):
            return []

        text = html.unescape(value)
        text = re.sub(r"<br\s*/?>", "\n", text, flags=re.IGNORECASE)
        text = re.sub(r"</?div[^>]*>", "\n", text, flags=re.IGNORECASE)
        text = re.sub(r"</?p[^>]*>", "\n", text, flags=re.IGNORECASE)

        # Suppression des autres balises et normalisation des espaces
        text = re.sub(r"<[^>]+>", "", text)
        text = text.replace("\xa0", " ")

        chunks = [chunk.strip() for chunk in re.findall(r"[+#-][^+#-]+", text) if chunk.strip()]

        if chunks:
            return chunks

        return [line.strip() for line in text.splitlines() if line.strip()]

    @staticmethod
    def parse_style_value(texte: str) -> str:
        if not isinstance(texte, str):
            return ""

        texte = html.unescape(texte)
        # Retirer les stéréotypes <<...>> et extraire le premier token alphanumérique
        cleaned = re.sub(r"<<.*?>>", " ", texte)
        match = re.search(r"[A-Za-z0-9_]+(?:\s+[A-Za-z0-9_]+)*", cleaned)
        return match.group(0).strip() if match else ""
