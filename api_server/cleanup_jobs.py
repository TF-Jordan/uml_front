from api_server.storage import cleanup_expired_jobs


def main() -> None:
    removed = cleanup_expired_jobs()
    print(f"Removed {removed} expired job(s)")


if __name__ == "__main__":
    main()
