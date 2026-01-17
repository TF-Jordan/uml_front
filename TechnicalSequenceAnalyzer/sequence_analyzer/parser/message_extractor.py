from typing import List, Optional, Tuple, Dict
from lxml import etree
import re

from models.diagram_model import Message, MessageType
from utils.xml_helpers import XMLHelper
from .participant_extractor import ParticipantExtractor


class MessageExtractor:
    '''Extrait les messages (appels de méthodes) d'un diagramme de séquence'''

    def __init__(self, cells: List[etree._Element], participant_extractor: ParticipantExtractor):
        self.cells = cells
        self.participant_extractor = participant_extractor
        self.step_counter = 1

    def extract(self) -> List[Message]:
        '''Extrait tous les messages du diagramme'''
        messages = []

        for cell in self.cells:
            if XMLHelper.is_message(cell):
                message = self._extract_message(cell)
                if message:
                    messages.append(message)

        # Trier par step
        messages.sort(key=lambda m: m.step)

        return messages

    def _extract_message(self, cell: etree._Element) -> Optional[Message]:
        '''Extrait un message depuis une cellule'''
        source_id = cell.get('source')
        target_id = cell.get('target')
        edge_geom = XMLHelper.get_edge_geometry(cell)

        if not source_id or not target_id:
            return None

        # Récupérer les participants
        from_participant = self.participant_extractor.get_participant_by_id(source_id)
        to_participant = self.participant_extractor.get_participant_by_id(target_id)

        # Extraire le texte du message
        message_text = XMLHelper.get_cell_value(cell)
        if not message_text:
            return None

        # Fallback: déduire les participants via les points de l'arête
        if not from_participant or not to_participant:
            src_point, tgt_point = XMLHelper.get_edge_points(cell)
            participants = list(self.participant_extractor.participants_map.values())

            if not from_participant:
                from_participant = self._nearest_participant(src_point, participants)
            if not to_participant:
                to_participant = self._nearest_participant(tgt_point, participants)

        if not from_participant or not to_participant:
            return None

        # Parser le message
        method, params, return_type = self._parse_message_text(message_text)

        # Déterminer le type
        style = XMLHelper.get_cell_style(cell)
        message_type = self._determine_message_type(style, from_participant.name, to_participant.name)

        # Inférer SQL si c'est une query
        sql_equivalent = self._infer_sql(method, message_type) if message_type in [MessageType.QUERY,
                                                                                   MessageType.UPDATE,
                                                                                   MessageType.INSERT,
                                                                                   MessageType.DELETE] else None

        message = Message(
            step=self.step_counter,
            **{"from": from_participant.name},
            to=to_participant.name,
            method=method,
            parameters=params,
            return_type=return_type,
            type=message_type,
            description=self._generate_description(method, from_participant.name, to_participant.name),
            sql_equivalent=sql_equivalent,
            is_async=self._is_async(style),
            geometry=edge_geom,
        )

        self.step_counter += 1
        return message

    def _parse_message_text(self, text: str) -> Tuple[str, List[str], Optional[str]]:
        '''Parse le texte d'un message pour extraire méthode, paramètres et type de retour'''
        # Format attendu: methodName(param1, param2): returnType
        # ou: methodName(param1: type1, param2: type2)

        method = text
        params = []
        return_type = None

        # Extraire le type de retour
        if ':' in text and ')' in text:
            parts = text.split(')')
            if len(parts) > 1:
                return_part = parts[1].strip()
                if return_part.startswith(':'):
                    return_type = return_part[1:].strip()
                text = parts[0] + ')'

        # Extraire la méthode et les paramètres
        if '(' in text and ')' in text:
            method = text[:text.index('(')].strip()
            params_str = text[text.index('(') + 1:text.rindex(')')].strip()

            if params_str:
                # Séparer les paramètres
                params = [p.strip() for p in params_str.split(',')]
        else:
            method = text.strip()

        return method, params, return_type

    def _determine_message_type(self, style: Dict[str, str], from_name: str, to_name: str) -> MessageType:
        '''Détermine le type de message'''

        # Message de retour (dashed)
        if style.get('dashed') == '1' or 'dashed=1' in str(style):
            return MessageType.RESPONSE

        # Self-call
        if from_name == to_name:
            return MessageType.SELF_CALL

        # Query vers entity/repository
        if any(keyword in to_name.lower() for keyword in ['table', 'repository', 'dao']):
            return MessageType.QUERY

        # Par défaut: request
        return MessageType.REQUEST

    def _infer_sql(self, method: str, message_type: MessageType) -> Optional[str]:
        '''Infère la requête SQL depuis le nom de la méthode'''
        method_lower = method.lower()

        # SELECT
        if any(keyword in method_lower for keyword in ['find', 'get', 'select', 'search', 'list']):
            return "SELECT * FROM table WHERE ..."

        # INSERT
        if any(keyword in method_lower for keyword in ['create', 'insert', 'add', 'save', 'enregistrer']):
            return "INSERT INTO table (...) VALUES (...)"

        # UPDATE
        if any(keyword in method_lower for keyword in ['update', 'modify', 'change', 'modifier']):
            return "UPDATE table SET ... WHERE ..."

        # DELETE
        if any(keyword in method_lower for keyword in ['delete', 'remove', 'supprimer']):
            return "DELETE FROM table WHERE ..."

        return None

    def _generate_description(self, method: str, from_name: str, to_name: str) -> str:
        '''Génère une description pour le message'''
        return f"{from_name} appelle {method} sur {to_name}"

    def _is_async(self, style: Dict[str, str]) -> bool:
        '''Détermine si le message est asynchrone'''
        return 'async' in str(style).lower()

    def _nearest_participant(self, point: Optional[tuple[float, float]], participants: List) -> Optional:
        """Retourne le participant le plus proche d'un point"""
        if not point or not participants:
            return None
        px, py = point
        best = None
        best_dist = None
        for p in participants:
            geom = getattr(p, 'geometry', None)
            if not geom:
                continue
            cx = geom.get('x', 0) + geom.get('width', 0) / 2
            cy = geom.get('y', 0) + geom.get('height', 0) / 2
            dist = (px - cx) ** 2 + (py - cy) ** 2
            if best_dist is None or dist < best_dist:
                best_dist = dist
                best = p
        return best
