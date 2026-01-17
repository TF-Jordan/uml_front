from rq import Worker

from api_server.queue import get_queue, get_redis


def main() -> None:
    queue = get_queue()
    worker = Worker([queue], connection=get_redis())
    worker.work()


if __name__ == "__main__":
    main()
