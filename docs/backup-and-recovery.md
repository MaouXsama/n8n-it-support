# Backup and Recovery

## PostgreSQL

The Azure PostgreSQL Flexible Server is configured with seven days of automated backup retention and storage auto-grow enabled.

The database is outside the Docker Compose stack and is managed by Azure. PostgreSQL recovery should be performed using the Azure portal or Azure CLI by restoring to a new server, validating the restored database, and updating the n8n database connection secret in Key Vault.

## n8n data

n8n workflow data and encryption configuration will be protected through the PostgreSQL database and Azure Key Vault. The Docker Compose deployment must not be treated as the only copy of application data.

## Recovery test

Before final acceptance, document one restore rehearsal or clearly record why it was not performed in the temporary assessment environment.
