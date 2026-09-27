#!/usr/bin/env bash
set -euo pipefail
KEY_VAULT_NAME="${1:?Key Vault name is required}"
az login --identity --allow-no-subscriptions --output none
PGHOST="$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name postgres-host --query value -o tsv)"
PGUSER="$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name postgres-user --query value -o tsv)"
PGPASSWORD="$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name postgres-password --query value -o tsv)"
PGDATABASE="$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name postgres-db --query value -o tsv)"
docker run --rm -e "PGPASSWORD=$PGPASSWORD" postgres:16-alpine psql "host=$PGHOST user=$PGUSER dbname=$PGDATABASE sslmode=require" -c "SELECT table_schema, table_name FROM information_schema.tables WHERE table_name = 'tickets';" -c "SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='tickets' ORDER BY ordinal_position;"
