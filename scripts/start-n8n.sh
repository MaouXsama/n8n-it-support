#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_DIR"

if [ ! -f ".env" ]; then
  echo "ERROR: .env file was not found."
  echo "Create .env from .env.example before starting the platform."
  exit 1
fi

echo "Starting n8n and PostgreSQL..."

docker compose \
  --env-file .env \
  -f docker/docker-compose.yml \
  up -d

echo "Waiting for services..."

sleep 10

docker compose \
  --env-file .env \
  -f docker/docker-compose.yml \
  ps

echo "n8n platform started successfully."
echo "n8n: http://localhost:5678"