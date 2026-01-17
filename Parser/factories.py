import re
import html
from typing import Dict, List
import logging

from Parser.regular_expression import RegularExpression

class Factories:

    logger = logging.getLogger(__name__)

    @staticmethod
    def create_class_structure(mxcell: Dict) -> Dict:

        print(f"===========class_value========={mxcell.get('@value')}")
        final_class_name = Factories.give_type_class(mxcell.get("@value"))
        print(f"===========final_class_name========={final_class_name}")
        class_name = RegularExpression.parse_style_value(final_class_name[1]) # Je dois extraire le nom de la classe
        print(f"===========final_class_name========={final_class_name}")
        print(f"===========class_name========={class_name}")
        return {
            "name": class_name,
            "type": final_class_name[0],
            "attributes": [],
            "methods": [],
            "relationships": []
        }



    # Parse le style d'une relation UML pour extraire les attributs pertinents.
    @staticmethod
    def parse_relationship_style(style: str)->Dict:
       required_fields = ["endArrow","endFill","dashed","startArrow","startFill"]
       result = {field: "" for field in required_fields}

       #Decoupage de la chaine style en pairs clé=valeur
       style_pairs = [pair.strip() for pair in style.split(";") if pair.strip()]

       for pair in style_pairs:
           if "=" not in pair:
               continue

           key, value = pair.split("=", 1)
           key = key.strip()

           if key in required_fields:
               result[key] = value.strip()

       return result


    # Détermine le type de relation UML basé sur les attributs de style.
    @staticmethod
    def determine_relationship_type(style_dict: Dict[str,str]) -> str:

        end_arrow = style_dict.get("endArrow", "")
        end_fill = style_dict.get("endFill", "")
        dashed = style_dict.get("dashed", "")
        start_arrow = style_dict.get("startArrow", "")
        start_fill = style_dict.get("startFill", "")

        #Héritage ou Implémentation
        if end_arrow == "block" and end_fill == "0":
            return "implementation" if dashed == "1" else "inheritance"

        #AgregationComposition
        if (end_arrow == "diamondThin" and end_fill == "1") or (end_arrow == "open" and start_arrow == "diamondThin" and start_fill == "1"):
            return "composition"

        #AgrégationPartagée
        if (end_arrow == "diamondThin" and end_fill == "0") or  (end_arrow == "open" and start_arrow == "diamondThin" and start_fill == "0"):
            return "agregation"

        return "association"


    @staticmethod
    def create_relationship_structure(mxcell: Dict) -> Dict:

        style_dict= Factories.parse_relationship_style(mxcell.get("@style"))
        relation_type= Factories.determine_relationship_type(style_dict)

        return {
            "name": RegularExpression.parse_style_value(mxcell.get("@value")),
            "source_name": mxcell.get("@source"),
            "target_name": mxcell.get("@target"),
            "edge": mxcell.get("@edge"),
            "style": Factories.parse_relationship_style(mxcell.get("@style")),
            "type": relation_type,
            "source_cardinality": "",
            "target_cardinality": ""
        }


    @staticmethod
    def create_attribute_structure(visibility: str, name: str, type_: str):
        return {
            "visibility": visibility,
            "attribute_name": name.strip(),
            "attribute_type": type_.strip()
        }

    @staticmethod
    def create_method_structure(visibility: str, name: str, type_: str, args: List[str]):
        return {
            "visibility": visibility,
            "method_name": name.strip(),
            "method_type": type_.strip(),
            "parameters": args
        }

    @staticmethod
    def create_arg_structure(arg: str):
        values = arg.strip().split()
        if len(values) >= 2:
            return {'param_type':values[0], 'param_name':values[1]}
        else:
            return {'param_type':'Object', 'param_name':values[0]}

    @staticmethod
    def factorize_output_lexer(output_lexer: Dict) -> Dict:

        # fonction pour refactoriser la sortie du lexer
        for relation in output_lexer["relationships"]:
            id_source = ""  # capture id
            for class_id, class_data in output_lexer["classes"].items():

                if relation["source_name"] == class_id:
                    print(f"=========Relation======{relation}")
                    relation["source_name"] = class_data["name"]
                    print(f"=========source_name========{relation['source_name']}\n")
                    print(f"=========source_name========{class_data['name']}\n")
                    id_source = class_id
                    print(f"=================class_id========{class_id}\n")

                elif relation["target_name"] == class_id:

                    relation["target_name"] = class_data["name"]
                    print(f"=========source_name========{relation['source_name']}\n")
                    print(f"=========source_name========{class_data['name']}\n")
                    id_source = class_id
            output_lexer["classes"][id_source]["relationships"].append(relation)

        output_lexer.pop("relationships")
        definitiveClass = {}
        newClass = {}

        for class_id, class_data in output_lexer["classes"].items():
            print(f"======class_name======{class_data['name']}")
            newKey = class_data["name"]
            class_data.pop("name")

            newClass[newKey] = class_data

        definitiveClass["classes"] = newClass

        return definitiveClass

    @staticmethod
    def give_type_class(class_name: str) -> list[str]:
        """Détermine le type d'une classe et normalise son nom."""

        # Constantes de types
        ABSTRACT = "abstractClass"
        INTERFACE = "interface"
        STANDARD = "class"

        # Validation
        if not isinstance(class_name, str) or not class_name.strip():
            raise ValueError("Le nom de classe doit être une chaîne non vide")

        # Désencoder les entités HTML avant détection (ex: &lt;&lt;interface&gt;&gt;)
        decoded_class_name = html.unescape(class_name)
        lower_case_class_name = decoded_class_name.lower()

        # Détection du type avec stéréotypes et mots-clés
        class_type = STANDARD
        needs_parsing = False

        # Stéréotypes explicites <<Interface>> ou <<Abstract>>
        if "<<" in lower_case_class_name and ">>" in lower_case_class_name:
            if "interface" in lower_case_class_name:
                class_type = INTERFACE
            elif "abstract" in lower_case_class_name:
                class_type = ABSTRACT
            needs_parsing = True
        elif "abstractclass" in lower_case_class_name or "abstract" in lower_case_class_name:
            class_type = ABSTRACT
            needs_parsing = True
        elif "interface" in lower_case_class_name:
            class_type = INTERFACE
            needs_parsing = True

        # Traitement du nom
        if needs_parsing:
            parsed_name = RegularExpression.parse_style_value(decoded_class_name)
            final_class_name = Factories.construct_class_name(parsed_name)
        else:
            final_class_name = Factories.construct_class_name(decoded_class_name)

        # Logging unifié
        Factories.logger.debug(f"Type détecté: {class_type}, Nom final: {final_class_name}")

        return [class_type, final_class_name]




    @staticmethod
    def construct_class_name(class_name: str) -> str:
        """
        Normalise un nom de classe en PascalCase.

        Args:
            class_name: Le nom brut de la classe à normaliser

        Returns:
            Le nom de classe formaté en PascalCase

        Raises:
            ValueError: Si class_name n'est pas une chaîne valide

        Examples:
             construct_class_name("")
            ""
             construct_class_name("   ")
            ""
             construct_class_name("classe")
            "Classe"
             construct_class_name("ma-classe_test")
            "MaClasseTest"
             construct_class_name("ma classe  exemple")
            "MaClasseExemple"
        """
        # Validation de l'entrée
        if not isinstance(class_name, str):
            raise ValueError("Le nom de classe doit être une chaîne de caractères")

        # Supprimer les espaces en début et fin
        name = class_name.strip()

        # Cas 1 et 2 : Chaîne vide ou espaces uniquement
        if not name:
            raise ValueError("Le nom de classe doit être une chaîne de caractères")

        # Convertir en minuscules
        lower_case_name = name.lower()

        # Cas 4 : Remplacer les caractères spéciaux par des espaces
        # On considère comme séparateurs : espace, tiret, underscore, point, virgule, etc.
        normalized_name = re.sub(r'[_\-\.,:;/\\]+', ' ', lower_case_name)

        # Découper par espaces (gère aussi les espaces multiples)
        words = normalized_name.split()

        # Cas 1 et 2 (bis) : Si après traitement il n'y a aucun mot
        if not words:
            return ""

        # Cas 3 et général : Capitaliser chaque mot et les joindre
        return ''.join(word.capitalize() for word in words)

    # Determiner les cardinalites de la relation source---label---target
    @staticmethod
    def relationship_association_attribs(mxcell: Dict, list_cell: List[Dict], relationship: Dict) -> Dict:

            """
                                Extrait les attributs d'une association
            """

            # liste des dictionnaires (cellules)
            cells = list(list_cell)

            print(f"======cells======: {cells} ")

            listmxcell_attributes = []
            cell_to_delete = []
            t = 0
            for cell in cells:

                if cell.get("@id") == mxcell.get("@id"):

                    print(f"======mxcell===={mxcell}")

                    for cell_in_slice in cells[cells.index(cell) + 1:]:

                        if mxcell.get("@id") == cell_in_slice.get("@parent"):
                            print(f"=======slice_cell======={cell_in_slice}")
                            listmxcell_attributes.append(cell_in_slice)

                            cell_to_delete.append(cell_in_slice)
                            t += 1


                        else:

                            break

                    break

            print(f"========attribute_relationship=======:{listmxcell_attributes}")

            list_mxcell_attributes = []

            if listmxcell_attributes:

                for cell in listmxcell_attributes:
                    print(f"======cell_before_parse_style======{cell}")
                    print(f"======cell_before_parse_style_value======{cell.get('@value')}")
                    list_mxcell_attributes.append(Factories.parse_style_value(cell.get("@value")))
                    print(f"===========cell_after_parse_style======{Factories.parse_style_value(cell.get('@value'))}")

                if len(listmxcell_attributes) == 3:

                    relationship["name"] = list_mxcell_attributes[0]
                    relationship["source_cardinality"] = list_mxcell_attributes[1]
                    relationship["target_cardinality"] = list_mxcell_attributes[2]

                elif t < 3:
                    relationship["name"] = Factories.parse_style_value(mxcell.get("@value"))
                    relationship["source_cardinality"] = list_mxcell_attributes[0]
                    relationship["target_cardinality"] = list_mxcell_attributes[1]

                else:
                    relationship["source_cardinality"] = ""
                    relationship["target_cardinality"] = ""

            if cell_to_delete:
                for cell in cell_to_delete:

                    list_cell.remove(cell)

            for cell in list_mxcell_attributes:
                print(f"=====attribut_association===={cell}")


            return relationship

    @staticmethod
    def parse_style_value(texte: str) -> str:

        i = 0
        while i < len(texte):
            if texte[i].isalpha() or texte[i].isdigit():
                # Extraire jusqu'au prochain '<'
                fin = texte.find("<", i)
                if fin == -1:
                    return texte[i:].strip()  # pas de '<', on prend jusqu'à la fin
                else:
                    return texte[i:fin].strip()
            else:
                # Avancer jusqu'au prochain '>'
                pos = texte.find(">", i)
                if pos == -1:
                    break  # pas de '>' trouvé
                i = pos + 1
        return ""  # rien trouvé
