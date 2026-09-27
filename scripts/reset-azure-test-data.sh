#!/usr/bin/env bash
set -euo pipefail
KEY_VAULT_NAME="${1:?Key Vault name is required}"
az login --identity --allow-no-subscriptions --output none
PGHOST="$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name postgres-host --query value -o tsv)"
PGUSER="$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name postgres-user --query value -o tsv)"
PGPASSWORD="$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name postgres-password --query value -o tsv)"
PGDATABASE="$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name postgres-db --query value -o tsv)"

docker run --rm -e "PGPASSWORD=$PGPASSWORD" postgres:16-alpine \
  psql "host=$PGHOST user=$PGUSER dbname=$PGDATABASE sslmode=require" \
  -v ON_ERROR_STOP=1 \
  -c "TRUNCATE TABLE notifications, tickets RESTART IDENTITY CASCADE;" \
  -c "SELECT 'tickets' AS table_name, COUNT(*) AS rows FROM tickets UNION ALL SELECT 'notifications', COUNT(*) FROM notifications;"
