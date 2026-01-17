from lxml import etree
from typing import Dict, List, Optional, Tuple
from pathlib import Path

from models.diagram_model import SequenceDiagram

from utils.xml_helpers import XMLHelper
from .participant_extractor import ParticipantExtractor
from .message_extractor import MessageExtractor
from .fragment_extractor import FragmentExtractor


class DrawIOParser:
    '''Parser principal pour les fichiers DrawIO'''

    def __init__(self, file_path: str, alias_map: Optional[Dict[str, str]] = None):
        self.file_path = Path(file_path)
        self.root = None
        self.mx_model = None
        self.cells = []
        self.alias_map = alias_map or {}

    def parse(self) -> SequenceDiagram:
        '''Parse le premier diagramme DrawIO et retourne un SequenceDiagram (compat)'''
        diagrams = self.parse_all()
        if not diagrams:
            raise ValueError("Aucun diagramme valide trouvé")
        return diagrams[0]

    def parse_all(self) -> List[SequenceDiagram]:
        '''Parse toutes les pages DrawIO et retourne une liste de SequenceDiagram'''

        # 1. Charger le XML
        self.root = XMLHelper.parse_drawio_file(str(self.file_path))

        # 2. Récupérer tous les diagrammes (pages)
        diagram_elements = XMLHelper.get_diagram_elements(self.root)
        if not diagram_elements:
            raise ValueError("Aucun élément diagram trouvé")

        diagrams: List[SequenceDiagram] = []

        for page_idx, diagram_elem in enumerate(diagram_elements):
            # 3. Récupérer le mxGraphModel
            self.mx_model = XMLHelper.get_mx_graph_model(diagram_elem)
            if self.mx_model is None:
                raise ValueError(f"Aucun mxGraphModel trouvé pour la page {diagram_elem.get('name', page_idx)}")

            # 4. Récupérer toutes les cellules
            self.cells = XMLHelper.get_all_cells(self.mx_model)

            # 4.b Récupérer et retirer le bloc de description éventuel
            description, filtered_cells = self._extract_use_case_description(self.cells, diagram_elem)
            self.cells = filtered_cells

            # 5. Créer les extracteurs
            participant_extractor = ParticipantExtractor(self.cells, alias_map=self.alias_map)
            message_extractor = MessageExtractor(self.cells, participant_extractor)

            # 6. Extraire les données
            participants = participant_extractor.extract()
            messages = message_extractor.extract()
            fragment_extractor = FragmentExtractor(self.cells, messages)
            fragments = fragment_extractor.extract()

            # 7. Créer le diagramme
            diagram_name = diagram_elem.get('name', self.file_path.stem)
            diagram_id = self._build_diagram_id(diagram_name, page_idx)
            inferred_use_case = description if description is not None else self._infer_use_case(diagram_name, participants, messages)

            sequence_diagram = SequenceDiagram(
                name=diagram_name,
                id=diagram_id,
                use_case=inferred_use_case,
                participants=participants,
                sequence_flow=messages,
                fragments=fragments
            )
            diagrams.append(sequence_diagram)

        return diagrams

    def _infer_use_case(self, name: str, participants: List, messages: List) -> str:
        '''Infère le cas d'usage depuis le nom et le contenu'''
        # TODO: Améliorer l'inférence avec de l'IA ou des règles plus sophistiquées
        return f"Cas d'usage décrit dans le diagramme {name}"

    def _extract_use_case_description(
        self,
        cells: List[etree._Element],
        diagram_elem: etree._Element,
    ) -> Tuple[Optional[str], List[etree._Element]]:
        """Repère un bloc texte balisé $#...#$; l'extrait (unique) et retire la cellule."""
        description_cells = []
        for cell in cells:
            if cell.get('edge') == '1':
                continue
            value = XMLHelper.get_cell_value(cell)
            stripped = value.strip()
            if stripped.startswith("$#") and stripped.endswith("#$"):
                description_cells.append((cell, stripped))

        if len(description_cells) > 1:
            namestr = diagram_elem.get('name', self.file_path.stem)
            raise ValueError(f"Plusieurs blocs de description détectés sur la page {namestr}; un seul bloc $#...#$ est autorisé.")

        description: Optional[str] = None
        if description_cells:
            cell, raw = description_cells[0]
            description = raw[2:-2]  # Conserver le contenu tel quel sans altérer la mise en forme
            cells = [c for c in cells if c is not cell]

        return description, cells

    def _build_diagram_id(self, diagram_name: str, page_idx: int) -> str:
        """Construit un identifiant stable pour les pages multiples."""
        base = self.file_path.stem
        safe_name = diagram_name.strip().replace(" ", "_") if diagram_name else f"page_{page_idx+1}"
        return f"{base}_{safe_name}"
