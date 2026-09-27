#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_DIR"

echo "Stopping n8n and PostgreSQL..."

docker compose \
  --env-file .env \
  -f docker/docker-compose.yml \
  down

echo "Services stopped."