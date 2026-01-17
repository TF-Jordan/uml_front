import json
from pathlib import Path
from typing import Dict, Any

from models.diagram_model import SequenceDiagram
from models.spring_boot_model import SpringBootMapping


class JSONGenerator:
    '''Génère des fichiers JSON depuis les modèles'''

    def __init__(self, output_dir: str):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def generate_diagram_json(self, diagram: SequenceDiagram) -> Path:
        '''Génère le JSON du diagramme de séquence'''
        output_file = self.output_dir / f"{diagram.id}_diagram.json"

        # Convertir en dict
        diagram_dict = diagram.model_dump(by_alias=True, exclude_none=True)

        # Sauvegarder
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(diagram_dict, f, indent=2, ensure_ascii=False)

        return output_file

    def generate_spring_boot_json(self, mapping: SpringBootMapping, diagram_id: str, stack: str = "spring") -> Path:
        '''Génère le JSON du mapping backend (nommage adapté au stack)'''
        output_file = self.output_dir / f"{diagram_id}_{stack}_mapping.json"

        # Convertir en dict
        mapping_dict = mapping.model_dump(by_alias=True, exclude_none=True)

        # Sauvegarder
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(mapping_dict, f, indent=2, ensure_ascii=False)

        return output_file

    def generate_complete_analysis(
            self,
            diagram: SequenceDiagram,
            mapping: SpringBootMapping,
            entities: Dict[str, Any] = None,
            stack: str = "spring"
    ) -> Path:
        '''Génère l'analyse complète combinée'''
        output_file = self.output_dir / f"{diagram.id}_complete_analysis_{stack}.json"

        complete = {
            "diagram_metadata": {
                "name": diagram.name,
                "id": diagram.id,
                "use_case": diagram.use_case,
                "complexity": diagram.complexity,
                "stack": stack,
            },
            "participants": [p.model_dump() for p in diagram.participants],
            "sequence_flow": [m.model_dump() for m in diagram.sequence_flow],
            "fragments": [f.model_dump() for f in diagram.fragments],
            "spring_boot_mapping": mapping.model_dump(exclude_none=True)
        }

        if entities:
            complete["existing_entities"] = entities

        # Sauvegarder
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(complete, f, indent=2, ensure_ascii=False)

        return output_file
