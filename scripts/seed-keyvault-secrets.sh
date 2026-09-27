#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 5 ]]; then
  echo "Usage: $0 <key-vault-name> <postgres-host> <postgres-db> <postgres-user> <postgres-password>"
  echo "Set N8N_ENCRYPTION_KEY in the environment before running this script."
  exit 1
fi

KEY_VAULT_NAME="$1"
POSTGRES_HOST="$2"
POSTGRES_DB="$3"
POSTGRES_USER="$4"
POSTGRES_PASSWORD="$5"

if [[ -z "${N8N_ENCRYPTION_KEY:-}" ]]; then
  echo "ERROR: N8N_ENCRYPTION_KEY is not set."
  exit 1
fi

set_secret() {
  local name="$1"
  local value="$2"
  az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "$name" \
    --value "$value" \
    --output none
}

set_secret postgres-host "$POSTGRES_HOST"
set_secret postgres-db "$POSTGRES_DB"
set_secret postgres-user "$POSTGRES_USER"
set_secret postgres-password "$POSTGRES_PASSWORD"
set_secret n8n-encryption-key "$N8N_ENCRYPTION_KEY"

echo "Required n8n and PostgreSQL secrets were stored in Key Vault."
