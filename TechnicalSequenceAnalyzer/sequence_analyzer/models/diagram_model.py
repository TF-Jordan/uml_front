from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from enum import Enum

class ParticipantType(str, Enum):
    ACTOR = "actor"
    BOUNDARY = "boundary"
    CONTROLLER = "controller"
    ENTITY = "entity"
    SERVICE = "service"

class MessageType(str, Enum):
    REQUEST = "request"
    RESPONSE = "response"
    QUERY = "query"
    UPDATE = "update"
    INSERT = "insert"
    DELETE = "delete"
    SELF_CALL = "self-call"
    ASYNC = "async"

class FragmentType(str, Enum):
    ALT = "ALT"
    OPT = "OPT"
    LOOP = "LOOP"
    PAR = "PAR"
    REF = "REF"
    BREAK = "BREAK"

class Participant(BaseModel):
    name: str
    type: ParticipantType
    role: str
    stereotype: Optional[str] = None
    id: Optional[str] = None
    geometry: Optional[Dict[str, float]] = None

class Message(BaseModel):
    step: int
    from_participant: str = Field(alias="from")
    to_participant: str = Field(alias="to")
    method: str
    parameters: List[str] = Field(default_factory=list)
    return_type: Optional[str] = None
    type: MessageType
    description: Optional[str] = None
    sql_equivalent: Optional[str] = None
    is_async: bool = False
    geometry: Optional[Dict[str, float]] = None

    class Config:
        populate_by_name = True

class FragmentBranch(BaseModel):
    guard: str
    label: Optional[str] = None
    interactions: List[Message] = Field(default_factory=list)
    geometry: Optional[Dict[str, float]] = None

class Fragment(BaseModel):
    type: FragmentType
    line_number: Optional[int] = None
    condition: Optional[str] = None
    description: Optional[str] = None
    nested: bool = False
    branches: List[FragmentBranch] = Field(default_factory=list)
    reference: Optional[str] = None  # Pour les REF
    interactions: List[Message] = Field(default_factory=list)
    geometry: Optional[Dict[str, float]] = None

class SequenceDiagram(BaseModel):
    name: str
    id: str
    use_case: str
    complexity: str = "medium"
    participants: List[Participant] = Field(default_factory=list)
    sequence_flow: List[Message] = Field(default_factory=list)
    fragments: List[Fragment] = Field(default_factory=list)
