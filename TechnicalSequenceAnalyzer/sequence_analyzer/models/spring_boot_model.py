from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class Endpoint(BaseModel):
    path: str
    http_method: str
    params: List[str] = Field(default_factory=list)
    return_type: str
    description: str
    calls_service: str
    security: Optional[str] = None

class Controller(BaseModel):
    name: str
    base_path: str
    endpoints: List[Endpoint] = Field(default_factory=list)

class ServiceMethod(BaseModel):
    name: str
    params: List[str] = Field(default_factory=list)
    return_type: str
    logic: List[str] = Field(default_factory=list)
    throws: List[str] = Field(default_factory=list)
    calls_repository: List[str] = Field(default_factory=list)

class Service(BaseModel):
    name: str
    annotations: List[str] = Field(default_factory=list)
    methods: List[ServiceMethod] = Field(default_factory=list)

class RepositoryQuery(BaseModel):
    method: str
    params: List[str] = Field(default_factory=list)
    return_type: str
    jpql: Optional[str] = None
    query_type: str

class Repository(BaseModel):
    name: str
    extends: str
    queries: List[RepositoryQuery] = Field(default_factory=list)

class EntityRelationship(BaseModel):
    type: str
    target_entity: str
    mapped_by: Optional[str] = None

class Entity(BaseModel):
    name: str
    table_name: Optional[str] = None
    fields: List[str] = Field(default_factory=list)
    relationships: List[EntityRelationship] = Field(default_factory=list)

class DTO(BaseModel):
    name: str
    fields: List[str] = Field(default_factory=list)
    validation: List[str] = Field(default_factory=list)
    purpose: str = "request"

class ExceptionDefinition(BaseModel):
    type: str
    extends: str = "RuntimeException"
    when: str
    http_status: str
    message: str

class TransactionConfig(BaseModel):
    required: bool
    annotation: str = "@Transactional"
    isolation_level: str = "READ_COMMITTED"
    rollback_on: List[str] = Field(default_factory=lambda: ["Exception.class"])
    notes: List[str] = Field(default_factory=list)

class SpringBootMapping(BaseModel):
    controllers: List[Controller] = Field(default_factory=list)
    services: List[Service] = Field(default_factory=list)
    repositories: List[Repository] = Field(default_factory=list)
    entities: List[Entity] = Field(default_factory=list)
    dtos: List[DTO] = Field(default_factory=list)
    exceptions: List[ExceptionDefinition] = Field(default_factory=list)
    transaction_management: Optional[TransactionConfig] = None