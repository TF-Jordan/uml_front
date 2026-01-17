# syntax=docker/dockerfile:1.4
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

COPY requirements.docker.txt /app/requirements.docker.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r /app/requirements.docker.txt

COPY . /app
RUN chmod +x /app/docker_entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/bin/sh", "/app/docker_entrypoint.sh"]
