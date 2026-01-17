# semantic_analyser_v2 vs semantic_analyzer

Cette version « v2 » remplace la logique historique de `semantic_analyzer` par une chaîne déterministe, découplée des services IA et testable localement. Ci-dessous, un guide méthodologique qui met chaque fonctionnalité en parallèle pour comprendre ce qui a changé.

## Vue d’ensemble

- `semantic_analyzer.SemanticAnalyzer.execute()` mélangeait chargement, appels Gemini et interprétation des relations.  
- `semantic_analyser_v2.pipeline.run_pipeline()` enchaîne trois modules purs (visibilités, types, relations) réutilisables individuellement.
- Les validations reposent désormais sur des mappings internes (`validators.SemanticValidator`) plutôt que sur un chat distant.
- Le fichier `semantic_analyser_v2/test_structure.json` fournit un scénario e-commerce riche (11 classes) qui sert de test de régression rapide pour l’ensemble du pipeline.

## Correspondance des méthodes clés

| Domaine | `semantic_analyzer` (legacy) | `semantic_analyser_v2` |
| --- | --- | --- |
| Chargement des classes | `SemanticAnalyzer.build_classes()` + `ModelsFactory.build_class_model()` récupèrent un dict et instancient des objets `Class`. | `structure_loader.load_structure_parser_file()` lit le JSON puis `normalize_structure_payload()` opère directement sur le dict (pas d’objets `Class`). |
| Interprétation des visibilités | `Interpreter.map_visibility_symbol()` et `Interpreter.interpret_visibility()` convertissent `+/-/#`. | `visibility_normalizer.normalize_visibility_value()` et `normalize_visibility_payload()` appliquent la même règle mais in-place sur le payload JSON. |
| Validation des types | `SemanticValidator.verify_types()` appelle Gemini via `google.generativeai`, nécessite une API key, normalise attributs/méthodes/args à la volée. | `SemanticValidator.normalize_type()` + `structure_loader.normalize_structure_payload()` utilisent des tables canoniques, gèrent génériques, arrays et cache; aucune dépendance réseau. |
| Relations UML | `Interpreter.interpret_relationship_style()` lit le style draw.io puis `Interpreter.interpret_relationships()` peuple `parent`, `aggregations`, `compositions`. | `relationships_transformer.process_relationships()` normalise les noms, restructure toutes les relations, ajoute `extends/implements`, génère attributs ou classes d’association via `append_*` helpers. |
| Orchestration | `SemanticAnalyzer.execute()` fait appel aux méthodes ci-dessus et retourne des objets `Class`. | `pipeline.run_pipeline()` orchestre visibilité → types → noms → relations et retourne un dictionnaire prêt pour le générateur de code. |
| Scripts CLI | Aucun exécutable dédié, seulement la classe Python. | `pipeline.py`, `visibility_normalizer.py` et `run_validator.py` exposent chaque étape via `argparse`. |
| Jeu de test | Non fourni : nécessite un JSON utilisateur + une clé Gemini. | `test_structure.json` (commerce en ligne) couvre héritages, implémentations, compositions, agrégations, associations et sert de test fonctionnel. |

## Détails par composant

### Chargement & normalisation des types
- **Legacy** : `SemanticAnalyzer.build_classes()` transformait les valeurs en `Class`/`Attribute`/`Method` puis `semantic_analyzer.validators.SemanticValidator.verify_types()` itérait sur les champs `_type` en consultant Gemini pour chaque nom (avec un cache local `types_dict`).
- **v2** : `structure_loader.load_structure_parser_file()` lit le JSON, `normalize_structure_payload()` détecte les champs (`attribute_type`, `method_type`, `param_type`, etc.) et appelle `SemanticValidator.normalize_type()` qui :
  1. nettoie les suffixes `[]` et les génériques (`_extract_generic`, `_split_generic_arguments`);
  2. cherche d’abord dans `_LANGUAGE_CANONICAL_TYPES`, puis dans la liste des classes connues, puis tente une correction via `difflib.get_close_matches`;
  3. retient le résultat en cache pour accélérer les occurrences suivantes.

### Interprétation des visibilités
- **Legacy** : `Interpreter.map_visibility_symbol()` remplaçait les symboles UML et `Interpreter.interpret_visibility()` mettait à jour les objets `Class`.
- **v2** : `visibility_normalizer.normalize_visibility_value()` convertit les symboles ou mots-clés déjà présents; `normalize_visibility_payload()` applique ce mapping directement dans le dictionnaire `payload["classes"][...]["attributes"|"methods"]`. Les fonctions sont également exposées via `normalize_visibility_file()` et un CLI `main()`.

### Transformation des relations
- **Legacy** : `Interpreter.interpret_relationship_style()` analysait la chaîne `style` (draw.io) pour distinguer héritage, agrégation, composition ou attribut simple, puis `Interpreter.interpret_relationships()` mettait à jour `parent`, `aggregations`, `compositions` sur chaque `Class`. Les associations bidirectionnelles ou les cardinalités n’étaient pas exploitées et il n’existait pas de détection des implémentations d’interface.
- **v2** : `relationships_transformer.process_relationships()` commence par `capitalize_class_names()` pour stabiliser les clés, indexe toutes les classes, puis :
  - `append_inheritance()` ajoute « extends » en s’assurant qu’une classe n’hérite qu’une fois (sinon `ValueError` explicite) ;
  - `append_implementation()` ajoute « implements » et clone les méthodes de l’interface si elles manquent dans la classe concrète ;
  - `append_other_relationship()` délègue aux agrégations/compositions (suffixes `$` et `#`), gère les associations 1→1 en ajoutant un attribut, et appelle `append_join_table()` pour les cardinalités *↔* (création d’une classe relationnelle intermédiaire).

### Orchestration & scripts
- **Legacy** : `SemanticAnalyzer.execute()` était la seule façade publique (pas de CLI), dépendait d’un `structured_json_data` déjà en mémoire et d’un `api_key` optionnel.
- **v2** : `pipeline.run_pipeline()` roule les quatre étapes clés (visibilité, types, normalisation des noms, relations) et est piloté par `pipeline.py` (CLI). `run_validator.py` expose juste la normalisation des types pour des diagnostics rapides.

## Jeu de test & validation

- **Legacy** : aucun corpus fourni — il fallait construire ses propres JSON et disposer d’une clé Gemini valide pour valider les types.
- **v2** : `semantic_analyser_v2/test_structure.json` décrit un domaine e-commerce complet (utilisateurs, rôles, produits, commandes, paiements, inventaire, notifications, promotions…). Ce fichier sert à :
  1. Vérifier manuellement chaque transformation (visibilités, types, relations).
  2. Régresser les cas compliqués (héritages multiples, agrégations imbriquées, cardinalités asymétriques) sans réseau.
  3. Aligner la génération de code avec les conventions choisies (`extends`, attributs suffixés `$/#`, classes d’association `_ref`).

En pratique, lancer `python semantic_analyser_v2/pipeline.py semantic_analyser_v2/test_structure.json --language java` reproduit l’équivalent de `SemanticAnalyzer.execute()` tout en restant 100 % local et déterministe.
