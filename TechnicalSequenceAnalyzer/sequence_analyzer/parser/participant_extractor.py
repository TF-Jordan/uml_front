from typing import List, Dict, Optional
from lxml import etree

from models.diagram_model import Participant, ParticipantType
from utils.xml_helpers import XMLHelper


class ParticipantExtractor:
    '''Extrait les participants (lifelines) d'un diagramme de séquence'''

    def __init__(self, cells: List[etree._Element], alias_map: Dict[str, str] = None):
        self.cells = cells
        self.participants_map: Dict[str, Participant] = {}
        self.alias_map = alias_map or {}
        self.alias_applied: List[str] = []

    def extract(self) -> List[Participant]:
        '''Extrait tous les participants du diagramme'''
        participants = []
        seen_names = set()

        for cell in self.cells:
            if XMLHelper.is_lifeline(cell):
                participant = self._extract_participant(cell)
                if participant:
                    if participant.name in seen_names:
                        continue
                    seen_names.add(participant.name)
                    participants.append(participant)
                    self.participants_map[cell.get('id')] = participant

        return participants

    def _extract_participant(self, cell: etree._Element) -> Participant:
        '''Extrait un participant depuis une cellule'''
        name = XMLHelper.get_cell_value(cell)
        cell_id = cell.get('id')
        style = XMLHelper.get_cell_style(cell)
        geometry = XMLHelper.get_cell_geometry(cell)

        # Déterminer le type
        participant_type = self._determine_type(style, name)

        # Alias éventuel
        alias = self._resolve_alias(cell_id, name)

        # Déterminer le rôle
        role = self._infer_role(name, participant_type)

        # Stéréotype
        stereotype = self._extract_stereotype(name)

        # Nettoyer le nom
        clean_name = self._clean_name(alias or name)
        if not clean_name:
            return None

        return Participant(
            name=clean_name,
            type=participant_type,
            role=role,
            stereotype=stereotype,
            id=cell_id,
            geometry=geometry
        )

    def _determine_type(self, style: Dict[str, str], name: str) -> ParticipantType:
        '''Détermine le type de participant'''
        name_lower = name.lower()

        # Actor
        if 'participant=umlActor' in style or 'umlActor' in style.get('participant', ''):
            return ParticipantType.ACTOR

        # Controller
        if any(keyword in name_lower for keyword in ['controller', 'controleur', 'system', 'système']):
            return ParticipantType.CONTROLLER

        # Entity / Repository
        if any(keyword in name_lower for keyword in ['table', 'repository', 'dao', 'database', 'db']):
            return ParticipantType.ENTITY

        # Service
        if 'service' in name_lower:
            return ParticipantType.SERVICE

        # Boundary (UI, Interface)
        if any(keyword in name_lower for keyword in ['ui', 'interface', 'view', 'page']):
            return ParticipantType.BOUNDARY

        # Par défaut : entity
        return ParticipantType.ENTITY

    def _infer_role(self, name: str, ptype: ParticipantType) -> str:
        '''Infère le rôle du participant'''
        role_map = {
            ParticipantType.ACTOR: "Utilisateur du système",
            ParticipantType.BOUNDARY: "Interface utilisateur",
            ParticipantType.CONTROLLER: "Orchestrateur de la logique métier",
            ParticipantType.ENTITY: "Accès aux données",
            ParticipantType.SERVICE: "Logique métier"
        }

        return role_map.get(ptype, "Participant du système")

    def _extract_stereotype(self, name: str) -> str:
        '''Extrait le stéréotype depuis le nom'''
        if '<<' in name and '>>' in name:
            start = name.index('<<')
            end = name.index('>>')
            return name[start:end + 2]
        return None

    def _clean_name(self, name: str) -> str:
        '''Nettoie le nom du participant'''
        # Retirer les stéréotypes
        if '<<' in name and '>>' in name:
            name = name.split('>>')[1] if '>>' in name else name

        # Retirer les retours à la ligne et espaces multiples
        name = ' '.join(name.split())

        # Retirer les backticks ou valeurs placeholder
        invalid_names = {'', '`'}
        if name in invalid_names:
            return ''

        return name.strip()

    def _resolve_alias(self, cell_id: str, raw_name: str) -> Optional[str]:
        """Retourne un alias si fourni via l'alias_map (par id ou par nom brut)"""
        if cell_id in self.alias_map:
            alias = self.alias_map[cell_id]
            self.alias_applied.append(f"{raw_name or cell_id} -> {alias}")
            return alias
        if raw_name in self.alias_map:
            alias = self.alias_map[raw_name]
            self.alias_applied.append(f"{raw_name} -> {alias}")
            return alias
        return None

    def get_participant_by_id(self, cell_id: str) -> Participant:
        '''Récupère un participant par son ID de cellule'''
        return self.participants_map.get(cell_id)
