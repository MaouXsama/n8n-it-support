# Key Vault Secrets

The deployment script expects these secret names:

| Secret name | Purpose |
|---|---|
| `postgres-host` | PostgreSQL Flexible Server hostname |
| `postgres-db` | n8n database name |
| `postgres-user` | PostgreSQL administrator/application user |
| `postgres-password` | PostgreSQL password |
| `n8n-encryption-key` | n8n encryption key |

Use `scripts/seed-keyvault-secrets.sh` after Terraform creates the Key Vault and PostgreSQL server. Do not commit secret values to GitHub or Terraform files.
