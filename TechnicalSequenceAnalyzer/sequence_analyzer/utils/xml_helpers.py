from lxml import etree
from typing import Optional, Dict, Any, List


class XMLHelper:
    '''Utilitaires pour manipuler les fichiers XML DrawIO'''

    @staticmethod
    def parse_drawio_file(file_path: str) -> etree._Element:
        '''Parse un fichier DrawIO et retourne l'arbre XML'''
        parser = etree.XMLParser(remove_blank_text=True)
        tree = etree.parse(file_path, parser)
        return tree.getroot()

    @staticmethod
    def get_diagram_element(root: etree._Element) -> Optional[etree._Element]:
        '''Récupère l'élément diagram principal'''
        diagram = root.find('.//diagram')
        return diagram

    @staticmethod
    def get_diagram_elements(root: etree._Element) -> List[etree._Element]:
        '''Récupère toutes les pages (diagram) disponibles'''
        return list(root.findall('.//diagram'))

    @staticmethod
    def get_mx_graph_model(diagram: etree._Element) -> Optional[etree._Element]:
        '''Récupère le mxGraphModel depuis un diagram'''
        if diagram is None:
            return None

        # Le contenu peut être dans un élément mxGraphModel direct
        # ou encodé dans le texte du diagram
        mx_model = diagram.find('.//mxGraphModel')
        if mx_model is not None:
            return mx_model

        # Sinon, essayer de parser le contenu texte
        content = diagram.text
        if content:
            try:
                return etree.fromstring(content)
            except:
                pass

        return None

    @staticmethod
    def get_all_cells(mx_model: etree._Element) -> List[etree._Element]:
        '''Récupère toutes les cellules du modèle'''
        return mx_model.findall('.//mxCell')

    @staticmethod
    def get_cell_style(cell: etree._Element) -> Dict[str, str]:
        '''Parse le style d'une cellule DrawIO'''
        style_str = cell.get('style', '')
        style_dict = {}

        for item in style_str.split(';'):
            if '=' in item:
                key, value = item.split('=', 1)
                style_dict[key] = value
            elif item:
                style_dict[item] = 'true'

        return style_dict

    @staticmethod
    def get_cell_value(cell: etree._Element) -> str:
        '''Récupère la valeur textuelle d'une cellule'''
        value = cell.get('value', '')

        # Nettoyer le HTML/XML
        if value:
            import re
            import html
            value = value.replace('<br>', '\\n')
            value = value.replace('&lt;', '<')
            value = value.replace('&gt;', '>')
            value = value.replace('&amp;', '&')
            # Retirer les balises HTML simples
            value = re.sub(r'<[^>]+>', '', value)
            value = html.unescape(value)

        return value.strip()

    @staticmethod
    def get_cell_geometry(cell: etree._Element) -> Optional[Dict[str, float]]:
        """Extrait la géométrie (x, y, width, height) si présente"""
        geom_elem = cell.find('mxGeometry')
        if geom_elem is None:
            return None
        try:
            return {
                'x': float(geom_elem.get('x', 0)),
                'y': float(geom_elem.get('y', 0)),
                'width': float(geom_elem.get('width', 0)),
                'height': float(geom_elem.get('height', 0)),
            }
        except (TypeError, ValueError):
            return None

    @staticmethod
    def get_edge_points(cell: etree._Element) -> tuple[Optional[tuple[float, float]], Optional[tuple[float, float]]]:
        """Extrait les points source/target d'une arête"""
        geom_elem = cell.find('mxGeometry')
        src = tgt = None
        if geom_elem is not None:
            for child in geom_elem:
                if child.tag != 'mxPoint':
                    continue
                try:
                    x = float(child.get('x', 0))
                    y = float(child.get('y', 0))
                except (TypeError, ValueError):
                    continue
                if child.get('as') == 'sourcePoint':
                    src = (x, y)
                elif child.get('as') == 'targetPoint':
                    tgt = (x, y)
        return src, tgt

    @staticmethod
    def get_edge_geometry(cell: etree._Element) -> Optional[Dict[str, float]]:
        """Construit une géométrie simple (centre, bbox) à partir des points source/target"""
        src, tgt = XMLHelper.get_edge_points(cell)
        if not src or not tgt:
            return None
        x1, y1 = src
        x2, y2 = tgt
        return {
            "x1": x1,
            "y1": y1,
            "x2": x2,
            "y2": y2,
            "cx": (x1 + x2) / 2,
            "cy": (y1 + y2) / 2,
            "minx": min(x1, x2),
            "maxx": max(x1, x2),
            "miny": min(y1, y2),
            "maxy": max(y1, y2),
        }

    @staticmethod
    def is_lifeline(cell: etree._Element) -> bool:
        '''Vérifie si une cellule est une lifeline'''
        style = XMLHelper.get_cell_style(cell)
        value = XMLHelper.get_cell_value(cell)

        return (
                'shape=umlLifeline' in style or
                'umlLifeline' in style.get('shape', '') or
                'participant' in style.get('shape', '').lower()
        )

    @staticmethod
    def is_message(cell: etree._Element) -> bool:
        '''Vérifie si une cellule est un message'''
        style = XMLHelper.get_cell_style(cell)
        # Considérer toute arête comme un message potentiel
        if cell.get('edge') == '1':
            return True
        source = cell.get('source')
        target = cell.get('target')
        return source is not None and target is not None

    @staticmethod
    def is_fragment(cell: etree._Element) -> bool:
        '''Vérifie si une cellule est un fragment combiné'''
        style = XMLHelper.get_cell_style(cell)
        value = XMLHelper.get_cell_value(cell).lower()

        fragment_keywords = ['alt', 'opt', 'loop', 'par', 'ref', 'break']

        return (
                'shape=umlFrame' in style or
                any(keyword in value for keyword in fragment_keywords)
        )

    @staticmethod
    def extract_fragment_type(cell: etree._Element) -> Optional[str]:
        '''Extrait le type de fragment (ALT, OPT, LOOP, etc.)'''
        value = XMLHelper.get_cell_value(cell).lower()

        if 'alt' in value:
            return 'ALT'
        elif 'opt' in value:
            return 'OPT'
        elif 'loop' in value:
            return 'LOOP'
        elif 'par' in value:
            return 'PAR'
        elif 'ref' in value:
            return 'REF'
        elif 'break' in value:
            return 'BREAK'

        return None
