#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/opt/n8n-project"
COMPOSE_FILE="$PROJECT_DIR/docker/docker-compose.azure.yml"
ENV_FILE="$PROJECT_DIR/.env.azure"
CADDY_TEMPLATE="$PROJECT_DIR/docker/Caddyfile"
CADDY_FILE="/etc/caddy/Caddyfile"

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <temporary-hostname> <key-vault-name>"
  exit 1
fi

TEMPORARY_HOSTNAME="$1"
KEY_VAULT_NAME="$2"

if [[ ! -f "$COMPOSE_FILE" || ! -f "$CADDY_TEMPLATE" ]]; then
  echo "ERROR: deployment files are missing from $PROJECT_DIR"
  exit 1
fi

echo "Authenticating with Azure through the VM managed identity..."
az login --identity --allow-no-subscriptions >/dev/null

get_secret() {
  local secret_name="$1"
  az keyvault secret show \
    --vault-name "$KEY_VAULT_NAME" \
    --name "$secret_name" \
    --query value \
    --output tsv
}

POSTGRES_HOST="$(get_secret postgres-host)"
POSTGRES_DB="$(get_secret postgres-db)"
POSTGRES_USER="$(get_secret postgres-user)"
POSTGRES_PASSWORD="$(get_secret postgres-password)"
N8N_ENCRYPTION_KEY="$(get_secret n8n-encryption-key)"
AUTH_JWT_SECRET="$(get_secret auth-jwt-secret)"

for value in POSTGRES_HOST POSTGRES_DB POSTGRES_USER POSTGRES_PASSWORD N8N_ENCRYPTION_KEY AUTH_JWT_SECRET; do
  if [[ -z "${!value}" ]]; then
    echo "ERROR: Key Vault returned an empty value for $value"
    exit 1
  fi
done

install -d -m 0750 "$PROJECT_DIR"

cat > "$ENV_FILE" <<EOF
POSTGRES_HOST=$POSTGRES_HOST
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY
AUTH_JWT_SECRET=$AUTH_JWT_SECRET
TEMPORARY_HOSTNAME=$TEMPORARY_HOSTNAME
EOF
chmod 0600 "$ENV_FILE"

sed "s|{\$TEMPORARY_HOSTNAME}|$TEMPORARY_HOSTNAME|g" "$CADDY_TEMPLATE" > "$CADDY_FILE"
chmod 0644 "$CADDY_FILE"

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d
systemctl enable --now caddy
caddy validate --config "$CADDY_FILE"
systemctl reload caddy

echo "Azure n8n deployment completed."
echo "n8n: https://$TEMPORARY_HOSTNAME/"
echo "Dashboard: https://$TEMPORARY_HOSTNAME/dashboard/"
