# Technical Sequence Analyzer - Node Roles

Description: Roles des noeuds presentes dans le diagramme d'architecture.

- main.py: Point d'entree CLI, orchestre parsing, mapping et generation.
- input_diagrams/*.drawio: Fichiers DrawIO fournis en entree.
- DrawIOParser: Parse le fichier DrawIO et collecte les cellules de diagramme.
- ParticipantExtractor: Extrait les participants (acteurs, systemes, composants).
- MessageExtractor: Extrait les messages/echanges entre participants.
- FragmentExtractor: Extrait les fragments (alt/opt/loop).
- XMLHelper: Utilitaires XML (lecture du fichier, extraction des pages et cellules).
- SequenceDiagram: Modele du diagramme de sequence (participants, messages, fragments, metadata).
- EntityMatcher: Charge et aligne les entites existantes (JSON normalise) avec le diagramme.
- BackendMapper: Convertit un SequenceDiagram en artefacts backend selon le stack choisi.
- BackendMapping: Modele des artefacts backend generes.
- JSONGenerator: Ecrit les fichiers JSON d'analyse et de mapping.
- PromptGenerator: Construit le prompt final pour l'IA.
- entities JSON: Entrees optionnelles pour enrichir le mapping.
- *_diagram.json: Sortie JSON du diagramme parse.
- *_mapping.json: Sortie JSON du mapping backend.
- *_complete_analysis_*.json: Sortie JSON combinee (diagramme + mapping + entites).
- *_prompt.md: Prompt texte final pour l'IA.
