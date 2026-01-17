from typing import List, Dict, Optional
from models.diagram_model import SequenceDiagram, Participant, Message, ParticipantType, MessageType
from models.spring_boot_model import (
    SpringBootMapping, Controller, Endpoint, Service, ServiceMethod,
    Repository, RepositoryQuery, DTO, ExceptionDefinition, TransactionConfig
)
from .entity_matcher import EntityMatcher


class SpringBootMapper:
    '''Mappe un diagramme de séquence vers des composants Spring Boot'''

    def __init__(self, diagram: SequenceDiagram, entity_matcher: Optional[EntityMatcher] = None):
        self.diagram = diagram
        self.entity_matcher = entity_matcher

    def map(self) -> SpringBootMapping:
        '''Effectue le mapping complet'''

        controllers = self._map_controllers()
        services = self._map_services()
        repositories = self._map_repositories()
        dtos = self._map_dtos()
        exceptions = self._map_exceptions()
        transaction_config = self._determine_transaction_config()

        return SpringBootMapping(
            controllers=controllers,
            services=services,
            repositories=repositories,
            dtos=dtos,
            exceptions=exceptions,
            transaction_management=transaction_config
        )

    def _map_controllers(self) -> List[Controller]:
        '''Génère les controllers depuis le diagramme'''
        controllers = []

        # Trouver les participants de type controller
        controller_participants = [
            p for p in self.diagram.participants
            if p.type == ParticipantType.CONTROLLER
        ]

        for participant in controller_participants:
            # Récupérer les messages vers ce controller
            incoming_messages = [
                m for m in self.diagram.sequence_flow
                if m.to_participant == participant.name and m.type == MessageType.REQUEST
            ]

            endpoints = []
            for msg in incoming_messages:
                endpoint = self._create_endpoint(msg)
                if endpoint:
                    endpoints.append(endpoint)

            if endpoints:
                controller = Controller(
                    name=f"{participant.name.replace(' ', '')}",
                    base_path=self._generate_base_path(participant.name),
                    endpoints=endpoints
                )
                controllers.append(controller)

        return controllers

    def _create_endpoint(self, message: Message) -> Optional[Endpoint]:
        '''Crée un endpoint depuis un message'''

        # Déterminer la méthode HTTP
        http_method = self._infer_http_method(message.method)

        # Générer le path
        path = self._generate_endpoint_path(message.method)

        # Paramètres
        params = self._format_endpoint_params(message.parameters)

        # Type de retour
        return_type = f"ResponseEntity<{message.return_type or 'Object'}>"

        # Service call
        service_call = f"service.{message.method}({', '.join(message.parameters)})"

        endpoint = Endpoint(
            path=path,
            http_method=http_method,
            params=params,
            return_type=return_type,
            description=message.description or f"Endpoint pour {message.method}",
            calls_service=service_call
        )

        return endpoint

    def _map_services(self) -> List[Service]:
        '''Génère les services depuis le diagramme'''
        services = []

        # Identifier les méthodes métier
        controller_participants = [
            p for p in self.diagram.participants
            if p.type == ParticipantType.CONTROLLER
        ]

        for participant in controller_participants:
            service_methods = []

            # Récupérer les messages sortants du controller
            outgoing_messages = [
                m for m in self.diagram.sequence_flow
                if m.from_participant == participant.name
            ]

            for msg in outgoing_messages:
                method = self._create_service_method(msg)
                if method:
                    service_methods.append(method)

            if service_methods:
                service = Service(
                    name=f"{participant.name.replace('Controller', 'Service')}",
                    annotations=["@Service", "@Transactional"],
                    methods=service_methods
                )
                services.append(service)

        return services

    def _create_service_method(self, message: Message) -> Optional[ServiceMethod]:
        '''Crée une méthode de service depuis un message'''

        logic_steps = self._generate_logic_steps(message)

        method = ServiceMethod(
            name=message.method,
            params=message.parameters,
            return_type=message.return_type or "void",
            logic=logic_steps,
            throws=["ResourceNotFoundException", "ValidationException"],
            calls_repository=[f"repository.{message.method}()"]
        )

        return method

    def _map_repositories(self) -> List[Repository]:
        '''Génère les repositories depuis le diagramme'''
        repositories = []

        # Trouver les participants de type entity
        entity_participants = [
            p for p in self.diagram.participants
            if p.type == ParticipantType.ENTITY
        ]

        for participant in entity_participants:
            # Récupérer les messages vers cette entité
            incoming_messages = [
                m for m in self.diagram.sequence_flow
                if m.to_participant == participant.name
            ]

            queries = []
            for msg in incoming_messages:
                query = self._create_repository_query(msg)
                if query:
                    queries.append(query)

            if queries:
                entity_name = self._extract_entity_name(participant.name)
                repository = Repository(
                    name=f"{entity_name}Repository",
                    extends=f"JpaRepository<{entity_name}, Long>",
                    queries=queries
                )
                repositories.append(repository)

        return repositories

    def _create_repository_query(self, message: Message) -> Optional[RepositoryQuery]:
        '''Crée une query de repository depuis un message'''

        query = RepositoryQuery(
            method=message.method,
            params=message.parameters,
            return_type=message.return_type or "List<Entity>",
            jpql=message.sql_equivalent,
            query_type=message.type.value.upper()
        )

        return query

    def _map_dtos(self) -> List[DTO]:
        '''Génère les DTOs depuis le diagramme'''
        dtos = []

        # Analyser les types de retour et paramètres pour identifier les DTOs
        dto_names = set()

        for msg in self.diagram.sequence_flow:
            if msg.return_type and 'DTO' in msg.return_type:
                dto_names.add(msg.return_type)

            for param in msg.parameters:
                if 'DTO' in param or 'dto' in param.lower():
                    dto_names.add(param.split()[0] if ' ' in param else param)

        for dto_name in dto_names:
            dto = DTO(
                name=dto_name,
                fields=["// TODO: Définir les champs"],
                validation=["@Valid"],
                purpose="request"
            )
            dtos.append(dto)

        return dtos

    def _map_exceptions(self) -> List[ExceptionDefinition]:
        '''Génère les exceptions depuis le diagramme'''
        exceptions = [
            ExceptionDefinition(
                type="ResourceNotFoundException",
                extends="RuntimeException",
                when="Ressource inexistante",
                http_status="404 NOT_FOUND",
                message="La ressource demandée n'existe pas"
            ),
            ExceptionDefinition(
                type="ValidationException",
                extends="RuntimeException",
                when="Validation échouée",
                http_status="400 BAD_REQUEST",
                message="Les données fournies sont invalides"
            )
        ]

        return exceptions

    def _determine_transaction_config(self) -> Optional[TransactionConfig]:
        '''Détermine si des transactions sont nécessaires'''

        # Vérifier s'il y a des opérations d'écriture
        has_write_operations = any(
            msg.type in [MessageType.UPDATE, MessageType.INSERT, MessageType.DELETE]
            for msg in self.diagram.sequence_flow
        )

        if has_write_operations:
            return TransactionConfig(
                required=True,
                notes=["Transactions nécessaires pour garantir la cohérence des données"]
            )

        return None

    # Méthodes utilitaires

    def _infer_http_method(self, method_name: str) -> str:
        '''Infère la méthode HTTP depuis le nom de la méthode'''
        method_lower = method_name.lower()

        if any(keyword in method_lower for keyword in ['get', 'find', 'list', 'search']):
            return "GET"
        elif any(keyword in method_lower for keyword in ['create', 'add', 'save']):
            return "POST"
        elif any(keyword in method_lower for keyword in ['update', 'modify', 'change']):
            return "PUT"
        elif any(keyword in method_lower for keyword in ['delete', 'remove']):
            return "DELETE"

        return "POST"

    def _generate_base_path(self, controller_name: str) -> str:
        '''Génère le chemin de base pour un controller'''
        name = controller_name.lower().replace('controller', '').replace('controleur', '')
        return f"/api/{name}s"

    def _generate_endpoint_path(self, method_name: str) -> str:
        '''Génère le path d'un endpoint'''
        return f"/{method_name.lower()}"

    def _format_endpoint_params(self, params: List[str]) -> List[str]:
        '''Formate les paramètres pour un endpoint'''
        formatted = []
        for param in params:
            if ':' in param:
                param_type, param_name = param.split(':')
                formatted.append(f"@RequestParam {param_type.strip()} {param_name.strip()}")
            else:
                formatted.append(f"@RequestParam String {param}")
        return formatted

    def _generate_logic_steps(self, message: Message) -> List[str]:
        '''Génère les étapes de logique pour une méthode de service'''
        steps = [
            f"// Appel repository: {message.method}",
            f"// TODO: Implémenter la logique métier"
        ]
        return steps

    def _extract_entity_name(self, participant_name: str) -> str:
        '''Extrait le nom de l'entité depuis le nom du participant'''
        return participant_name.replace('Table_', '').replace('Repository', '').strip()
