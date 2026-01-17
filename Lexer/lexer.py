import xmltodict
from typing import Dict, List, Tuple
import re
from helpers.utils import Utils


class Lexer:

    def __init__(self, xml_data: str):
        self.xml_data = xml_data
        self.initial_json_data: List[Dict] = list()


    def execute(self) -> Dict:
        initial_json_data = xmltodict.parse(self.xml_data)

        # Conversion des clés en minuscules
        initial_json_data = Utils.lowercase_keys(initial_json_data)

        # Extraction du diagramme
        diagram = initial_json_data.get("mxfile", {}).get("diagram")
        ignored_cells = []

        if isinstance(diagram, dict):
            self.initial_json_data = diagram["mxgraphmodel"]["root"]["mxcell"]
        elif isinstance(diagram, list):
            self.initial_json_data = diagram[0]["mxgraphmodel"]["root"]["mxcell"]
        else:
            ignored_cells.append("No diagram detected during the xml to json conversion")
            print("\n".join(ignored_cells))
            raise RuntimeError("No diagram detected during the xml to json conversion")

        # Nettoyage des valeurs pour limiter le bruit HTML
        for cell in self.initial_json_data:
            if isinstance(cell, dict) and "@value" in cell:
                cell["@value"] = self._clean_value(cell.get("@value"))

        if ignored_cells:
            print("Ignored cells/info during lexing:")
            for item in ignored_cells:
                print(f"- {item}")

        return self.initial_json_data

    def _clean_value(self, value: str) -> str:
        """Supprime le HTML simple et trim les valeurs."""
        if not isinstance(value, str):
            return value
        text = re.sub(r"<[^>]+>", " ", value)
        return text.strip()
