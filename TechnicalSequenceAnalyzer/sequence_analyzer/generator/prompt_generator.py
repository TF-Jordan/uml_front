from typing import Dict, List, Optional
from pathlib import Path

from models.diagram_model import SequenceDiagram
from models.spring_boot_model import SpringBootMapping


class PromptGenerator:
    '''Génère des prompts textuels pour la génération de code'''

    def __init__(self, output_dir: str):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def generate_prompt(
            self,
            diagram: SequenceDiagram,
            mapping: SpringBootMapping,
            entities: Dict = None,
            stack: str = "spring",
            known_diagram_names: Optional[List[str]] = None
    ) -> str:
        '''Génère le prompt complet pour l'IA'''

        prompt = self.render_prompt(diagram, mapping, entities, stack, known_diagram_names)

        # Sauvegarder
        output_file = self.output_dir / f"{diagram.id}_prompt.md"
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(prompt)

        return prompt

    def render_prompt(
            self,
            diagram: SequenceDiagram,
            mapping: SpringBootMapping,
            entities: Dict = None,
            stack: str = "spring",
            known_diagram_names: Optional[List[str]] = None
    ) -> str:
        '''Construit le prompt sans l'écrire sur disque'''

        stack_display = {
            "spring": "Spring Boot (Java)",
            "fastapi": "FastAPI (Python)",
            "laravel": "Laravel 12 (PHP)",
            "nestjs": "NestJS 11 (TypeScript)",
            "dart": "Dart Shelf (Dart)",
            "fiber": "Go Fiber (Go)"
        }.get(stack, stack)

        prompt = f'''# Génération de code pour: {diagram.name}

## Contexte du projet

Type: Application REST API
Stack cible: {stack_display}
Diagramme analysé: {diagram.id}
Cas d'usage: {diagram.use_case}
'''
        if diagram.use_case:
            prompt += f"\n## Description du cas d'usage\n\n{diagram.use_case}\n\n"

        # Entités existantes
        if entities:
            prompt += self._add_existing_entities_section(entities)

        # Participants
        prompt += self._add_participants_section(diagram)

        # Flux de séquence
        prompt += self._add_sequence_flow_section(diagram)

        # Fragments d'interaction
        prompt += self._add_fragments_section(diagram, known_diagram_names)

        # Controllers
        prompt += self._add_controllers_section(mapping, stack)

        # Services
        prompt += self._add_services_section(mapping, stack)

        # Repositories
        prompt += self._add_repositories_section(mapping, stack)

        # DTOs
        prompt += self._add_dtos_section(mapping, stack)

        # Exceptions
        prompt += self._add_exceptions_section(mapping)

        # Instructions finales
        prompt += self._add_final_instructions(stack)

        return prompt

    def _add_existing_entities_section(self, entities: Dict) -> str:
        '''Ajoute la section des entités existantes'''
        section = "## Entités existantes dans le projet\n\n"

        for entity_name, entity_data in entities.items():
            section += f"### {entity_name}\n"
            section += f"- **Type**: {entity_data.get('type', 'class')}\n"

            if entity_data.get('attributes'):
                section += "- **Attributs**:\n"
                for attr in entity_data['attributes']:
                    section += f"  - `{attr.get('attribute_name')}`: {attr.get('attribute_type')}\n"

            if entity_data.get('methods'):
                section += "- **Méthodes**:\n"
                for method in entity_data['methods']:
                    section += f"  - `{method.get('method_name')}()`\n"

            section += "\n"

        return section

    def _add_participants_section(self, diagram: SequenceDiagram) -> str:
        '''Ajoute la section des participants'''
        section = "## Participants du diagramme\n\n"

        for p in diagram.participants:
            section += f"- **{p.name}** ({p.type.value}): {p.role}\n"

        section += "\n"
        return section

    def _add_sequence_flow_section(self, diagram: SequenceDiagram) -> str:
        '''Ajoute la section du flux de séquence'''
        section = "## Flux de séquence principal\n\n"

        for i, msg in enumerate(diagram.sequence_flow[:10], 1):  # Limiter à 10 premiers messages
            section += f"{i}. **{msg.from_participant}** → **{msg.to_participant}**: `{msg.method}()`\n"
            if msg.description:
                section += f"   - {msg.description}\n"

        if len(diagram.sequence_flow) > 10:
            section += f"\n_... et {len(diagram.sequence_flow) - 10} autres interactions_\n"

        section += "\n"
        return section

    def _add_fragments_section(self, diagram: SequenceDiagram, known_diagram_names: Optional[List[str]] = None) -> str:
        '''Ajoute la section des fragments d'interaction'''
        if not diagram.fragments:
            return ""

        max_items = 100
        name_map = self._build_reference_map(known_diagram_names)
        section = "## Fragments d'interaction (ALT/OPT/LOOP/PAR/REF/BREAK)\n\n"
        section += "Utiliser ces fragments pour modéliser conditions, boucles, branches et références.\n\n"

        for idx, fragment in enumerate(diagram.fragments, 1):
            section += f"### Fragment {idx}: {fragment.type.value}\n\n"
            if fragment.condition:
                section += f"- **Condition**: {fragment.condition}\n"
            if fragment.description:
                section += f"- **Description**: {fragment.description}\n"
            if fragment.reference:
                section += f"- **Référence**: {fragment.reference}\n"
                normalized = self._normalize_reference(fragment.reference)
                if name_map and normalized in name_map:
                    ref_name = name_map[normalized]
                    section += f"- **Renvoi**: Voir la section «Génération de code pour: {ref_name}».\n"
                else:
                    section += "- **Renvoi**: Aucune page correspondante détectée dans ce fichier.\n"

            if fragment.branches:
                section += "- **Branches**:\n"
                for b_idx, branch in enumerate(fragment.branches, 1):
                    guard = branch.guard or "[condition]"
                    section += f"  - **Branche {b_idx}** {guard}\n"
                    section += self._format_fragment_interactions(branch.interactions, indent="    ", max_items=max_items)
            else:
                section += self._format_fragment_interactions(fragment.interactions, max_items=max_items)

            section += "\n"

        return section

    def _format_fragment_interactions(self, interactions: List, indent: str = "", max_items: int = 100) -> str:
        if not interactions:
            return f"{indent}- **Interactions**: Aucune interaction associée.\n"

        lines = f"{indent}- **Interactions**:\n"
        for msg in interactions[:max_items]:
            lines += f"{indent}  - **{msg.from_participant}** → **{msg.to_participant}**: `{msg.method}()`\n"
            if msg.description:
                lines += f"{indent}    - {msg.description}\n"

        if len(interactions) > max_items:
            lines += f"{indent}  - ... et {len(interactions) - max_items} autres interactions\n"

        return lines

    def _build_reference_map(self, names: Optional[List[str]]) -> Dict[str, str]:
        if not names:
            return {}

        mapping: Dict[str, str] = {}
        for name in names:
            normalized = self._normalize_reference(name)
            if normalized and normalized not in mapping:
                mapping[normalized] = name
        return mapping

    def _normalize_reference(self, text: str) -> str:
        if not text:
            return ""
        normalized = " ".join(text.strip().split())
        return normalized.lower()


    def _add_controllers_section(self, mapping: SpringBootMapping, stack: str = "spring") -> str:
        '''Ajoute la section des controllers'''
        section = "## Controllers à générer\n\n"

        for controller in mapping.controllers:
            section += f"### {controller.name}\n\n"
            section += f"**Base Path**: `{controller.base_path}`\n\n"
            section += "**Endpoints**:\n\n"

            for endpoint in controller.endpoints:
                section += f"#### `{endpoint.http_method} {endpoint.path}`\n\n"
                section += f"- **Description**: {endpoint.description}\n"
                section += f"- **Paramètres**: {', '.join(endpoint.params) if endpoint.params else 'Aucun'}\n"
                section += f"- **Retour**: `{endpoint.return_type}`\n"
                section += f"- **Appelle**: `{endpoint.calls_service}`\n"
                if endpoint.security:
                    section += f"- **Sécurité**: `{endpoint.security}`\n"
                section += "\n"

        return section

    def _add_services_section(self, mapping: SpringBootMapping, stack: str = "spring") -> str:
        '''Ajoute la section des services'''
        section = "## Services à générer\n\n"

        code_lang = {
            "spring": "java",
            "fastapi": "python",
            "laravel": "php",
            "nestjs": "typescript",
            "dart": "dart",
            "fiber": "go",
        }.get(stack, "java")

        for service in mapping.services:
            section += f"### {service.name}\n\n"
            if stack not in ("laravel", "nestjs", "dart", "fiber"):
                section += f"**Annotations**: {', '.join(service.annotations)}\n\n"
            elif stack == "nestjs":
                section += "**Decorators**: `@Injectable()`\n\n"
            elif stack == "dart":
                section += "**Pattern**: Service class with Repository injection\n\n"
            elif stack == "fiber":
                section += "**Pattern**: Service struct with repository dependency\n\n"
            section += "**Méthodes**:\n\n"

            for method in service.methods:
                section += f"#### `{method.name}({', '.join(method.params)}): {method.return_type}`\n\n"
                section += f"**Logique métier**:\n```{code_lang}\n"
                for step in method.logic:
                    section += f"{step}\n"
                section += "```\n\n"

        return section

    def _add_repositories_section(self, mapping: SpringBootMapping, stack: str = "spring") -> str:
        '''Ajoute la section des repositories'''
        section = "## Repositories à générer\n\n"

        for repo in mapping.repositories:
            section += f"### {repo.name}\n\n"
            if stack == "laravel":
                section += f"**Implements**: `{repo.name}Interface`\n\n"
            elif stack == "nestjs":
                section += f"**Implements**: `I{repo.name}`\n"
                section += "**Uses**: TypeORM Repository\n\n"
            elif stack == "dart":
                section += f"**Implements**: `I{repo.name}`\n"
                section += "**Pattern**: In-memory or database implementation\n\n"
            elif stack == "fiber":
                section += "**Pattern**: Repository struct using GORM\n\n"
            else:
                section += f"**Extends**: `{repo.extends}`\n\n"
            section += "**Requêtes personnalisées**:\n\n"

            for query in repo.queries:
                section += f"#### `{query.method}()`\n\n"
                section += f"- **Type**: {query.query_type}\n"
                section += f"- **Retour**: `{query.return_type}`\n"
                if query.jpql and stack == "nestjs":
                    section += f"- **TypeORM Query**: (à adapter avec QueryBuilder)\n"
                elif query.jpql and stack == "dart":
                    section += f"- **Dart Query**: (à adapter avec filtres/recherche)\n"
                elif query.jpql and stack != "laravel":
                    section += f"- **JPQL**: `{query.jpql}`\n"
                elif query.jpql and stack == "laravel":
                    section += f"- **Eloquent Query**: (à adapter)\n"
                section += "\n"

        return section

    def _add_dtos_section(self, mapping: SpringBootMapping, stack: str = "spring") -> str:
        '''Ajoute la section des DTOs'''
        if stack == "laravel":
            section = "## Form Requests / Resources à créer\n\n"
        elif stack == "nestjs":
            section = "## DTOs avec class-validator à créer\n\n"
        elif stack == "dart":
            section = "## DTOs / Request Models à créer\n\n"
        elif stack == "fiber":
            section = "## DTOs / Request Models à créer\n\n"
        else:
            section = "## DTOs à créer\n\n"

        for dto in mapping.dtos:
            section += f"### {dto.name}\n\n"
            section += f"**Purpose**: {dto.purpose}\n\n"
            section += "**Champs**:\n"
            for field in dto.fields:
                section += f"- {field}\n"
            section += "\n"

        return section

    def _add_exceptions_section(self, mapping: SpringBootMapping) -> str:
        '''Ajoute la section des exceptions'''
        section = "## Exceptions à gérer\n\n"

        for exc in mapping.exceptions:
            section += f"### {exc.type}\n\n"
            section += f"- **Quand**: {exc.when}\n"
            section += f"- **Status HTTP**: {exc.http_status}\n"
            section += f"- **Message**: \"{exc.message}\"\n\n"

        return section

    def _add_final_instructions(self, stack: str = "spring") -> str:
        '''Ajoute les instructions finales pour la génération'''

        if stack == "laravel":
            return '''## Instructions de génération

Produire le code Laravel 12 complet en respectant les spécifications ci-dessus :

1. Créer tous les Controllers avec leurs méthodes CRUD
2. Implémenter tous les Services avec leur logique métier
3. Générer tous les Repositories avec leurs interfaces et implémentations
4. Créer les Form Requests pour la validation si nécessaire
5. Implémenter les Exceptions personnalisées
6. Utiliser l'injection de dépendances via le constructeur
7. Appliquer les bonnes pratiques Laravel (Repository Pattern, Service Layer)
8. Ajouter les commentaires PHPDoc nécessaires

Format de sortie souhaité : Code PHP complet, prêt à être intégré dans un projet Laravel 12 existant.
'''
        elif stack == "fastapi":
            return '''## Instructions de génération

Produire le code FastAPI complet en respectant les spécifications ci-dessus :

1. Créer tous les Routers avec leurs endpoints
2. Implémenter tous les Services avec leur logique métier
3. Générer tous les Repositories avec leurs méthodes
4. Créer tous les Schemas Pydantic avec validation
5. Implémenter les Exceptions personnalisées avec HTTPException
6. Utiliser l'injection de dépendances FastAPI (Depends)
7. Appliquer les bonnes pratiques FastAPI (async/await, type hints)
8. Ajouter les docstrings nécessaires

Format de sortie souhaité : Code Python complet, prêt à être intégré dans un projet FastAPI existant.
'''
        elif stack == "nestjs":
            return '''## Instructions de génération

Produire le code NestJS 11 complet en respectant les spécifications ci-dessus :

1. Créer tous les Controllers avec les décorateurs Swagger (@ApiTags, @ApiOperation, @ApiResponse)
2. Implémenter tous les Services avec injection de dépendances (@Injectable)
3. Générer tous les Repositories avec leurs interfaces et implémentations TypeORM
4. Créer tous les DTOs avec class-validator (@IsString, @IsNumber, @IsOptional, etc.)
5. Implémenter les Exceptions personnalisées (NotFoundException, BadRequestException, etc.)
6. Utiliser l'injection de dépendances NestJS via constructeur
7. Appliquer les bonnes pratiques NestJS (modules par entité, Repository Pattern, Service Layer)
8. Configurer TypeORM pour la gestion des entités et relations

Format de sortie souhaité : Code TypeScript complet, prêt à être intégré dans un projet NestJS 11 existant.
'''
        elif stack == "dart":
            return '''## Instructions de génération

Produire le code Dart Shelf complet en respectant les spécifications ci-dessus :

1. Créer tous les Controllers avec shelf_router (@Route annotations)
2. Implémenter tous les Services avec injection de dépendances via constructeur
3. Générer tous les Repositories avec leurs interfaces et implémentations
4. Créer tous les Models avec fromJson/toJson et copyWith
5. Implémenter les réponses d'erreur standardisées (ResponseUtils)
6. Utiliser l'injection de dépendances manuelle via constructeurs
7. Appliquer les bonnes pratiques Dart (Repository Pattern, Service Layer, types stricts)
8. Ajouter les middlewares CORS et JSON si nécessaire

Format de sortie souhaité : Code Dart complet, prêt à être intégré dans un projet Dart Shelf existant.
'''
        elif stack == "fiber":
            return '''## Instructions de génération

Produire le code Go Fiber complet en respectant les spécifications ci-dessus :

1. Créer tous les Handlers avec leurs endpoints Fiber
2. Implémenter tous les Services avec leur logique métier
3. Générer tous les Repositories avec GORM
4. Créer tous les Models Go avec tags JSON/GORM
5. Implémenter les erreurs standardisées (404/400)
6. Utiliser l'injection de dépendances via constructeurs
7. Appliquer les bonnes pratiques Go (interfaces, séparation handlers/services/repos)
8. Ajouter les commentaires GoDoc nécessaires

Format de sortie souhaité : Code Go complet, prêt à être intégré dans un projet Fiber existant.
'''
        else:
            return '''## Instructions de génération

Produire le code Spring Boot complet en respectant les spécifications ci-dessus :

1. Créer tous les Controllers avec leurs endpoints
2. Implémenter tous les Services avec leur logique métier
3. Générer tous les Repositories avec leurs requêtes
4. Créer tous les DTOs avec validation
5. Implémenter toutes les Exceptions personnalisées
6. Ajouter les annotations Spring appropriées (@RestController, @Service, @Repository, etc.)
7. Appliquer les bonnes pratiques Spring Boot (injection de dépendances, gestion des transactions, etc.)
8. Ajouter les commentaires JavaDoc nécessaires

Format de sortie souhaité : Code Java complet, prêt à être compilé et intégré dans un projet Spring Boot existant.
'''
