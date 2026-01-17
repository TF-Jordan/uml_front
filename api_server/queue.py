import redis
from rq import Queue

from api_server.settings import REDIS_URL


def get_redis() -> redis.Redis:
    return redis.Redis.from_url(REDIS_URL)


def get_queue(name: str = "uml2code") -> Queue:
    return Queue(name, connection=get_redis())
