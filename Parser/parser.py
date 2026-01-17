
from typing import Dict, List, Tuple

from Parser.validators import Validators
from Parser.factories import Factories
from Parser.regular_expression import RegularExpression

class Parser:

    def __init__(self, initial_json_data: str):
        self.initial_json_data =  initial_json_data
        self.structured_data = dict()
        self.root_id = None
        self.sub_root_id = None



    def execute(self) -> Dict:
        """Convertit le JSON initial en structure hiérarchique"""



        self.structured_data = {"classes": {}}
        self.root_id, self.sub_root_id = self._find_root_ids(self.initial_json_data)

        self._normalize_internal_cell_ids()  # (ajouté). Normaliser les cellules internes

        print (f"root_id {self.root_id}")
        print (f"sub_root_id {self.sub_root_id}")

        # Liste temporaire pour stocker les relations
        temp_relationships = []

        # Premier passage : classes
        remaining_cells = []
        for mxcell in self.initial_json_data:
            if mxcell.get("@id") in [self.root_id, self.sub_root_id]:
                continue

            if Validators.is_class(mxcell, self.sub_root_id):
                try:
                    self.structured_data["classes"][mxcell.get("@id")] = Factories.create_class_structure(mxcell)
                except ValueError:
                    # Classe non exploitable (nom vide/invalid) : on ignore
                    continue
            elif Validators.is_relation(mxcell, self.sub_root_id):
                relationship = Factories.create_relationship_structure(mxcell)
                relationship = Factories.relationship_association_attribs(mxcell, self.initial_json_data, relationship)
                # ajout de la relation dans le fichier temporaire
                temp_relationships.append(relationship)
            else:
                remaining_cells.append(mxcell)

        # Deuxième passage : attributs et méthodes
        for mxcell in remaining_cells:
            parent_id = mxcell.get("@parent")
            if parent_id not in self.structured_data["classes"]:
                continue

            if Validators.is_method(mxcell, self.sub_root_id):
                for method_chunk in RegularExpression.split_members(mxcell.get("@value", "") or ""):
                    visibility, name, type_, _args = RegularExpression.parse_method_value(method_chunk)
                    args = [Factories.create_arg_structure(arg) for arg in _args]
                    method = Factories.create_method_structure(visibility, name, type_, args)
                    self.structured_data["classes"][parent_id]["methods"].append(method)

            elif Validators.is_attribute(mxcell, self.sub_root_id):
                for attribute_chunk in RegularExpression.split_members(mxcell.get("@value", "") or ""):
                    visibility, name, type_ = RegularExpression.parse_attribute_value(attribute_chunk)
                    attribute = Factories.create_attribute_structure(visibility, name, type_)
                    self.structured_data["classes"][parent_id]["attributes"].append(attribute)


        # (ajouté) - Troisième passage : distribution des relations dans les classes
        for relationship in temp_relationships:
            source_id = relationship.get("source_name")
            target_id = relationship.get("target_name")

            if source_id not in self.structured_data["classes"] or target_id not in self.structured_data["classes"]:
                continue

            source_name = self.structured_data["classes"][source_id]["name"]
            target_name = self.structured_data["classes"][target_id]["name"]

            relation_for_source = relationship.copy()
            relation_for_source["source_name"] = source_name
            relation_for_source["target_name"] = target_name
            self.structured_data["classes"][source_id]["relationships"].append(relation_for_source)

            if target_id != source_id:
                relation_for_target = relationship.copy()
                relation_for_target["source_name"] = source_name
                relation_for_target["target_name"] = target_name
                self.structured_data["classes"][target_id]["relationships"].append(relation_for_target)

        self._replace_class_ids_with_names()
        return self.structured_data




    def _find_root_ids(self, json_data: List[Dict]) -> Tuple[str, str]:
        """Trouve les IDs root et sub_root"""
        self.root_id = next((cell["@id"] for cell in json_data if len(cell.keys()) == 1), None)
        self.sub_root_id = next((cell["@id"] for cell in json_data
                                 if len(cell.keys()) == 2 and cell.get("@parent") == self.root_id), None)
        return self.root_id, self.sub_root_id

    def _fix_relationship_attribs(self, relationship: Dict, initial_json_data: List[Dict]) -> None:
        # fix bad source and target in relationships
        for mxcell in initial_json_data:

            parent = mxcell.get('@parent')

            if relationship['source_name'].lower() == mxcell.get('@id').lower():
                relationship['source_name'] = parent if not parent is None else relationship['source']

            print(f"=============relationship['target_name'].lower()========={relationship['target_name'].lower()}")
            print(f"=============relationship['target_name']========={relationship['target_name']}")
            print(f"=============mxcell.get('@id').lower()========={mxcell.get('@id').lower()}")
            print(f"=============mxcell.get('@id')========={mxcell.get('@id')}")

            if relationship['target_name'].lower() == mxcell.get('@id').lower():
                print(f"=============relationship['target_name']========={relationship['target_name']}")
                relationship['target_name'] = parent if not parent is None else relationship['target']

    def _normalize_internal_cell_ids(self) -> None:
        """
        Normalise les IDs des cellules internes en les remplaçant par l'ID
        de leur cellule principale (classe parente).

        Cette méthode garantit que les relations pointent toujours vers la cellule
        principale de la classe, même si l'utilisateur les a connectées à une
        cellule interne (attributs ou méthodes).
        """
        id_mapping = {}

        # Première phase : construire la carte de correspondance ID cellule interne -> ID cellule principale
        for mxcell in self.initial_json_data:
            # Si c'est un attribut ou une méthode, mapper son ID vers l'ID de sa classe parente
            if Validators.is_attribute(mxcell, self.sub_root_id) or Validators.is_method(mxcell, self.sub_root_id):
                cell_id = mxcell.get("@id")
                parent_id = mxcell.get("@parent")
                id_mapping[cell_id] = parent_id

        # Deuxième phase : appliquer la normalisation sur toutes les cellules
        # Pour chaque cellule du diagramme
        for mxcell in self.initial_json_data:
            # Si cette cellule a un @source qui pointe vers un attribut/méthode
            if "@source" in mxcell and mxcell["@source"] in id_mapping:
                # Remplacer par l'ID de la classe principale
                mxcell["@source"] = id_mapping[mxcell["@source"]]
                # Exemple: "id_attribut_2" devient "id_classe_B"

            # Même chose pour @target
            if "@target" in mxcell and mxcell["@target"] in id_mapping:
                mxcell["@target"] = id_mapping[mxcell["@target"]]
        print(self.initial_json_data)

    def _replace_class_ids_with_names(self) -> None:
        """
        Remplace les IDs des classes (clés du dictionnaire) par leurs noms.
        """
        new_classes = {}

        for class_id, class_data in self.structured_data["classes"].items():
            class_name = class_data.get("name")

            if class_name:
                new_classes[class_name] = class_data
            else:
                new_classes[class_id] = class_data

        self.structured_data["classes"] = new_classes
