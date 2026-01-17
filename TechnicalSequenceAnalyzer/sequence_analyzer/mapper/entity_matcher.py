import json
from typing import Dict, List, Optional
from pathlib import Path


class EntityMatcher:
    '''Matche les entités du diagramme avec celles du debug_output.json'''

    def __init__(self, debug_output_path: str):
        self.debug_output_path = Path(debug_output_path)
        self.entities = {}
        self._load_entities()

    def _load_entities(self):
        '''Charge les entités depuis debug_output.json'''
        if self.debug_output_path.exists():
            with open(self.debug_output_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # Extraire les classes
            for project_name, project_data in data.items():
                if 'classes' in project_data:
                    self.entities.update(project_data['classes'])

    def find_entity(self, participant_name: str) -> Optional[Dict]:
        '''Trouve l'entité correspondante depuis le nom du participant'''
        # Nettoyer le nom
        clean_name = self._clean_participant_name(participant_name)

        # Recherche exacte
        if clean_name in self.entities:
            return self.entities[clean_name]

        # Recherche partielle
        for entity_name, entity_data in self.entities.items():
            if clean_name.lower() in entity_name.lower():
                return entity_data
            if entity_name.lower() in clean_name.lower():
                return entity_data

        return None

    def _clean_participant_name(self, name: str) -> str:
        '''Nettoie le nom du participant pour le matching'''
        # Retirer Table_, Repository_, etc.
        name = name.replace('Table_', '')
        name = name.replace('Repository', '')
        name = name.replace('_', '')

        return name.strip()

    def get_entity_attributes(self, entity_name: str) -> List[Dict]:
        '''Récupère les attributs d'une entité'''
        entity = self.find_entity(entity_name)
        if entity and 'attributes' in entity:
            return entity['attributes']
        return []

    def get_entity_methods(self, entity_name: str) -> List[Dict]:
        '''Récupère les méthodes d'une entité'''
        entity = self.find_entity(entity_name)
        if entity and 'methods' in entity:
            return entity['methods']
        return []

    def get_all_entities(self) -> Dict:
        '''Retourne toutes les entités'''
        return self.entities
