from pathlib import Path
from typing import Dict, Any

class Config:
    # Chemins
    BASE_DIR = Path(__file__).parent
    INPUT_DIR = BASE_DIR / "input_diagrams"
    OUTPUT_DIR = BASE_DIR / "output_analysis"
    TEMPLATES_DIR = BASE_DIR / "templates"

    # Configuration DrawIO
    DRAWIO_NAMESPACES = {
        'mxfile': 'mxGraphModel',
        'diagram': 'diagram',
        'mxCell': 'mxCell'
    }

    # Mapping des types de participants
    PARTICIPANT_TYPES = {
        'umlActor': 'actor',
        'umlLifeline': 'boundary',
        'shape=umlLifeline': 'entity',
        'swimlane': 'controller'
    }

    # Mapping des fragments UML
    FRAGMENT_TYPES = {
        'alt': 'ALT',
        'opt': 'OPT',
        'loop': 'LOOP',
        'par': 'PAR',
        'ref': 'REF',
        'break': 'BREAK'
    }

    # Configuration Spring Boot
    SPRING_BOOT_CONFIG = {
        'base_package': 'com.example',
        'api_base_path': '/api',
        'default_http_methods': ['GET', 'POST', 'PUT', 'DELETE'],
        'transaction_isolation': 'READ_COMMITTED'
    }

    @classmethod
    def ensure_directories(cls):
        cls.INPUT_DIR.mkdir(exist_ok=True)
        cls.OUTPUT_DIR.mkdir(exist_ok=True)
        cls.TEMPLATES_DIR.mkdir(exist_ok=True)