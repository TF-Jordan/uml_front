#!/bin/sh
set -eu

if [ "${1:-}" = "docs" ]; then
  port="${DOCS_PORT:-5555}"
  docs_dir="/app/documents/documentation"
  if [ ! -d "$docs_dir" ]; then
    docs_dir="/app/documents"
  fi
  if [ ! -d "$docs_dir" ]; then
    echo "Docs directory not found: $docs_dir" >&2
    exit 1
  fi
  echo "Serving docs on http://0.0.0.0:$port"
  exec python -m http.server "$port" --directory "$docs_dir"
fi

exec python /app/run_from_config.py "$@"
