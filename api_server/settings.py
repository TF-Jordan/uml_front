from pathlib import Path
import os

BASE_DIR = Path(__file__).resolve().parents[1]
JOB_STORE = Path(os.getenv("UML2CODE_JOB_STORE", BASE_DIR / "job_store"))
REDIS_URL = os.getenv("UML2CODE_REDIS_URL", "redis://localhost:6379/0")
DEFAULT_RETAIN_DAYS = int(os.getenv("UML2CODE_RETAIN_DAYS", "3"))
