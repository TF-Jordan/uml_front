import sys
from pathlib import Path
import argparse

from config import Config
from parser.drawio_parser import DrawIOParser
from mapper.spring_boot_mapper import SpringBootMapper
from mapper.entity_matcher import EntityMatcher
from generator.json_generator import JSONGenerator
from generator.prompt_generator import PromptGenerator

# Normalisation sémantique (types/relations) avant usage
try:
    from Semantic_Analyzer.structure_loader import normalize_structure_file
except Exception:
    normalize_structure_file = None  # Si indisponible, on continue sans normalisation


def main():
    parser = argparse.ArgumentParser(description='Analyse des diagrammes de séquence DrawIO')
    parser.add_argument('input_file', help='Chemin vers le fichier DrawIO')
    parser.add_argument('--entities', help='Chemin vers debug_output.json', default=None)
    parser.add_argument('--output', help='Répertoire de sortie', default='output_analysis')
    parser.add_argument('--use-case', dest='use_case', help='Description métier à injecter dans le prompt', default=None)
    parser.add_argument('--stack', choices=['spring', 'fastapi', 'laravel', 'nestjs', 'dart', 'fiber'], default='spring', help='Stack cible pour le prompt')

    args = parser.parse_args()

    # Vérifier que le fichier existe
    input_path = Path(args.input_file)
    if not input_path.exists():
        print(f"Erreur: Le fichier {input_path} n'existe pas")
        sys.exit(1)

    print(f"\\nAnalyse du diagramme: {input_path.name}")
    print("=" * 60)

    # 1. Parser le diagramme
    print("\\nÉtape 1/5: Parsing du fichier DrawIO...")
    try:
        parser = DrawIOParser(str(input_path))
        diagrams = parser.parse_all()
        print(f"{len(diagrams)} diagramme(s) parsé(s)")
        for d in diagrams:
            print(f"   - {d.name} ({len(d.participants)} participants, {len(d.sequence_flow)} messages, {len(d.fragments)} fragments)")
    except Exception as e:
        print(f"Erreur lors du parsing: {e}")
        sys.exit(1)

    # 2. Matcher avec les entités existantes
    entity_matcher = None
    entities_dict = None
    if args.entities:
        print(f"\\nÉtape 2/5: Matching avec les entités existantes...")
        try:
            entities_path = args.entities
            if normalize_structure_file is not None:
                try:
                    entities_dict = normalize_structure_file(entities_path, language="java", known_types=None)
                    print("   (Normalisation Semantic_Analyzer appliquée)")
                except Exception as ne:
                    print(f"   (Avertissement: normalisation Semantic_Analyzer échouée: {ne})")
                    entities_dict = None
            if entities_dict is None:
                entity_matcher = EntityMatcher(entities_path)
                entities_dict = entity_matcher.get_all_entities()
            print(f"{len(entities_dict)} entités chargées")
        except Exception as e:
            print(f"Avertissement: {e}")
    else:
        print("\\nÉtape 2/5: Pas d'entités existantes fournies")

    json_generator = JSONGenerator(args.output)
    prompt_generator = PromptGenerator(args.output)
    diagram_names = [diagram.name for diagram in diagrams]

    combined_prompts = []

    for diagram in diagrams:
        print(f"\\n=== Traitement de la page: {diagram.name} ===")

        # Override use case si fourni en argument
        if args.use_case:
            diagram.use_case = args.use_case

        # 3. Mapper vers backend
        print("\\nÉtape 3/5: Mapping des artefacts backend...")
        try:
            mapper = SpringBootMapper(diagram, entity_matcher)
            spring_boot_mapping = mapper.map()
            print(f"Mapping généré:")
            print(f"   - {len(spring_boot_mapping.controllers)} controllers")
            print(f"   - {len(spring_boot_mapping.services)} services")
            print(f"   - {len(spring_boot_mapping.repositories)} repositories")
            print(f"   - {len(spring_boot_mapping.dtos)} DTOs")
        except Exception as e:
            print(f"Erreur lors du mapping: {e}")
            sys.exit(1)

        # 4. Générer les JSONs
        print(f"\\nÉtape 4/5: Génération des fichiers JSON...")
        try:
            diagram_file = json_generator.generate_diagram_json(diagram)
            print(f"{diagram_file}")

            spring_file = json_generator.generate_spring_boot_json(spring_boot_mapping, diagram.id, stack=args.stack)
            print(f"{spring_file}")

            complete_file = json_generator.generate_complete_analysis(diagram, spring_boot_mapping, entities_dict, stack=args.stack)
            print(f"{complete_file}")
        except Exception as e:
            print(f"Erreur lors de la génération JSON: {e}")
            sys.exit(1)

        # 5. Générer le prompt (agrégé ensuite)
        print(f"\\nÉtape 5/5: Génération du prompt (contenu agrégé)...")
        try:
            entities_for_prompt = entities_dict
            if isinstance(entities_dict, dict) and "classes" in entities_dict:
                entities_for_prompt = entities_dict.get("classes") or {}

            prompt_content = prompt_generator.render_prompt(
                diagram,
                spring_boot_mapping,
                entities_for_prompt,
                stack=args.stack,
                known_diagram_names=diagram_names,
            )
            combined_prompts.append((diagram.name, prompt_content))
        except Exception as e:
            print(f"Erreur lors de la génération du prompt: {e}")
            sys.exit(1)

    # Écriture du prompt unique agrégé
    if combined_prompts:
        separator = "\n\n---\n\n"
        aggregated = separator.join([content for _, content in combined_prompts])
        combined_file = Path(args.output) / f"{input_path.stem}_prompt.md"
        combined_file.write_text(aggregated, encoding="utf-8")
        print(f"\\nPrompt agrégé écrit dans: {combined_file}")

    print("\\n" + "=" * 60)
    print("Analyse terminée avec succès.")
    print(f"Tous les fichiers sont dans: {args.output}/")
    print("\\nProchaine étape: utilisez le fichier *_prompt.md pour la génération de code.")


if __name__ == '__main__':
    main()
