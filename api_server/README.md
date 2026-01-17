# UML2Code API Server (RQ)

Minimal async API using FastAPI + Redis + RQ.

## Run

1) Start Redis
2) Start worker:
   `python -m api_server.worker`
3) Start API:
   `uvicorn api_server.main:app --reload`

## Endpoints

- `POST /jobs` (multipart form)
- `GET /jobs/{id}`
- `GET /jobs/{id}/logs`
- `GET /jobs/{id}/result.zip`
- `GET /jobs/{id}/normalized.json`
- `POST /jobs/{id}/cancel`
- `DELETE /jobs/{id}`
