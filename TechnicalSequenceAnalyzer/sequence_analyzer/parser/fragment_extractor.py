from typing import List, Optional, Dict, Tuple
from lxml import etree

from models.diagram_model import Fragment, FragmentType, FragmentBranch, Message
from utils.xml_helpers import XMLHelper


class FragmentExtractor:
    '''Extrait les fragments combinés (ALT, LOOP, OPT, etc.)'''

    def __init__(self, cells: List[etree._Element], messages: List[Message]):
        self.cells = cells
        self.messages = messages

    def extract(self) -> List[Fragment]:
        '''Extrait tous les fragments du diagramme'''
        fragments = []

        for cell in self.cells:
            if XMLHelper.is_fragment(cell):
                fragment = self._extract_fragment(cell)
                if fragment:
                    fragments.append(fragment)

        # Associer les messages aux fragments/branches
        if fragments and self.messages:
            self._attach_messages_to_fragments(fragments, self.messages)

        return fragments

    def _extract_fragment(self, cell: etree._Element) -> Optional[Fragment]:
        '''Extrait un fragment depuis une cellule'''
        fragment_type_str = XMLHelper.extract_fragment_type(cell)
        if not fragment_type_str:
            return None

        try:
            fragment_type = FragmentType(fragment_type_str)
        except ValueError:
            return None

        value = XMLHelper.get_cell_value(cell)

        # Extraire la condition
        condition = self._extract_condition(value)

        # Extraire la description
        description = self._extract_description(value, fragment_type)

        # Pour REF, extraire la référence
        reference = None
        if fragment_type == FragmentType.REF:
            reference = self._extract_reference(value)

        geometry = XMLHelper.get_cell_geometry(cell)

        branches = self._extract_branches(cell, fragment_type, geometry)

        fragment = Fragment(
            type=fragment_type,
            condition=condition,
            description=description,
            reference=reference,
            branches=branches,
            geometry=geometry,
        )

        return fragment

    def _extract_condition(self, text: str) -> Optional[str]:
        '''Extrait la condition depuis le texte du fragment'''
        # Chercher [condition]
        import re
        match = re.search(r'\[([^\]]+)\]', text)
        if match:
            return match.group(1).strip()

        # Chercher après le type de fragment
        lines = text.split('\\n')
        if len(lines) > 1:
            return lines[1].strip()

        return None

    def _extract_description(self, text: str, ftype: FragmentType) -> str:
        '''Génère une description pour le fragment'''
        descriptions = {
            FragmentType.ALT: "Condition alternative",
            FragmentType.OPT: "Fragment optionnel",
            FragmentType.LOOP: "Boucle itérative",
            FragmentType.PAR: "Exécution parallèle",
            FragmentType.REF: "Référence à un autre diagramme",
            FragmentType.BREAK: "Interruption de flux"
        }

        return descriptions.get(ftype, "Fragment combiné")

    def _extract_reference(self, text: str) -> Optional[str]:
        '''Extrait la référence pour un fragment REF'''
        lines = text.split('\\n')
        for line in lines:
            if 'ref' not in line.lower():
                return line.strip()
        return None

    def _extract_branches(self, cell: etree._Element, fragment_type: FragmentType, geometry: Optional[Dict[str, float]]) -> List[FragmentBranch]:
        """Construit des branches à partir des conditions détectées et des sous-cellules du fragment."""
        branches: List[FragmentBranch] = []
        conditions = []
        text = XMLHelper.get_cell_value(cell)
        if text:
            conditions = [c.strip() for c in text.splitlines() if c.strip()]

        if fragment_type in {FragmentType.ALT, FragmentType.OPT, FragmentType.PAR}:
            if not conditions:
                # Si aucune condition explicite, créer 2 branches génériques
                conditions = ["[condition1]", "[else]"]
            # Sous-cellules qui peuvent représenter des branches
            sub_geoms = self._extract_branch_regions(cell, geometry, len(conditions))
            for idx, cond in enumerate(conditions):
                geom = sub_geoms[idx] if idx < len(sub_geoms) else None
                branches.append(FragmentBranch(guard=cond, interactions=[], geometry=geom))
        elif fragment_type == FragmentType.LOOP:
            branches.append(FragmentBranch(guard=conditions[0] if conditions else "[loop]", interactions=[], geometry=geometry))
        elif fragment_type == FragmentType.BREAK:
            branches.append(FragmentBranch(guard=conditions[0] if conditions else "[break]", interactions=[], geometry=geometry))
        elif fragment_type == FragmentType.REF:
            branches.append(FragmentBranch(guard=conditions[0] if conditions else "[ref]", interactions=[], geometry=geometry))
        else:
            if conditions:
                for cond in conditions:
                    branches.append(FragmentBranch(guard=cond, interactions=[], geometry=geometry))

        return branches

    def _attach_messages_to_fragments(self, fragments: List[Fragment], messages: List[Message]) -> None:
        """Associe les messages aux fragments et répartit dans les branches selon la position relative."""
        for fragment in fragments:
            geom = fragment.geometry
            if not geom:
                continue

            # Messages inclus dans le rectangle du fragment
            included: List[Tuple[Message, float, float]] = []
            for msg in messages:
                mgeom = msg.geometry or {}
                cx = mgeom.get("cx")
                cy = mgeom.get("cy")
                if cx is None or cy is None:
                    continue
                if (geom.get("x", 0) <= cx <= geom.get("x", 0) + geom.get("width", 0) and
                        geom.get("y", 0) <= cy <= geom.get("y", 0) + geom.get("height", 0)):
                    included.append((msg, cx, cy))

            if not included:
                continue

            # Répartition des messages dans les branches par tranche horizontale
            if fragment.branches:
                branches = fragment.branches
                for msg, cx, cy in included:
                    assigned = False
                    for idx, br in enumerate(branches):
                        bgeom = br.geometry
                        if bgeom:
                            if (bgeom.get("x", 0) <= cx <= bgeom.get("x", 0) + bgeom.get("width", 0) and
                                    bgeom.get("y", 0) <= cy <= bgeom.get("y", 0) + bgeom.get("height", 0)):
                                br.interactions.append(msg)
                                assigned = True
                                break
                    if not assigned:
                        # fallback: choisir la branche dont le centre est le plus proche
                        best_idx = 0
                        best_dist = None
                        for i, b in enumerate(branches):
                            bg = b.geometry or geom or {}
                            bx = bg.get("x", 0) + (bg.get("width", 0) or 0) / 2
                            by = bg.get("y", 0) + (bg.get("height", 0) or 0) / 2
                            dist = (cx - bx) ** 2 + (cy - by) ** 2
                            if best_dist is None or dist < best_dist:
                                best_dist = dist
                                best_idx = i
                        branches[best_idx].interactions.append(msg)
            else:
                fragment.interactions.extend([m for m, _, _ in included])

    def _extract_branch_regions(self, fragment_cell: etree._Element, frag_geom: Optional[Dict[str, float]], expected_branches: int) -> List[Dict[str, float]]:
        """
        Déduit des régions de branche :
        - privilégie les sous-cellules du fragment,
        - essaie de déduire des séparateurs verticaux (lignes fines),
        - sinon découpe horizontalement en bandes égales.
        """
        geoms = []
        frag_id = fragment_cell.get('id')
        fx = frag_geom.get("x", 0) if frag_geom else 0
        fy = frag_geom.get("y", 0) if frag_geom else 0
        fw = frag_geom.get("width", 0) if frag_geom else 0
        fh = frag_geom.get("height", 0) if frag_geom else 0

        # Sous-cellules directes (potentielles branches)
        child_geoms = []
        v_separators = []
        h_separators = []
        for cell in self.cells:
            if cell.get('parent') == frag_id:
                g = XMLHelper.get_cell_geometry(cell)
                if not g:
                    continue
                w = g.get("width", 0) or 0
                h = g.get("height", 0) or 0
                # Ligne verticale probable (séparateur)
                if w <= max(5.0, h * 0.1):
                    v_separators.append(g)
                    continue
                # Ligne horizontale probable (séparateur)
                if h <= max(5.0, w * 0.1):
                    h_separators.append(g)
                    continue
                child_geoms.append(g)

        # Si des séparateurs verticaux sont trouvés, découper en bandes verticales
        if v_separators and fw:
            xs = [fx] + sorted(g["x"] for g in v_separators if "x" in g and g["x"] is not None)
            xs.append(fx + fw)
            geoms = [
                {
                    "x": xs[i],
                    "y": fy,
                    "width": xs[i + 1] - xs[i],
                    "height": fh,
                }
                for i in range(len(xs) - 1)
            ]

        # Sinon, si des séparateurs horizontaux sont trouvés, découper en bandes horizontales
        if not geoms and h_separators and fh:
            ys = [fy] + sorted(g["y"] for g in h_separators if "y" in g and g["y"] is not None)
            ys.append(fy + fh)
            geoms = [
                {
                    "x": fx,
                    "y": ys[i],
                    "width": fw,
                    "height": ys[i + 1] - ys[i],
                }
                for i in range(len(ys) - 1)
            ]

        # Sinon, utiliser les sous-cellules directes
        if not geoms and child_geoms:
            geoms = child_geoms

        # Sinon, sans sous-branches ni séparateurs, retourner une seule région (pas de découpe arbitraire)
        if not geoms and frag_geom:
            geoms = [frag_geom]

        return geoms
