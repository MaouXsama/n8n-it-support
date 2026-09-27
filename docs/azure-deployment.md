# Azure Deployment Runbook

This runbook describes the deployment already represented by the Terraform and Docker files. Do not commit `terraform.tfvars`, `.env`, Terraform state, plan files, or secret values.

## 1. Provision infrastructure

From the project root:

```powershell
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
terraform -chdir=terraform plan -out=n8n.tfplan
terraform -chdir=terraform apply n8n.tfplan
terraform -chdir=terraform output
```

The deployment creates a new resource group named `n8n-project` in East US. The PostgreSQL Flexible Server is created in Canada Central to match the project reference architecture.

## 2. Seed Key Vault

Create these secret names in the Key Vault output by Terraform:

```text
postgres-host
postgres-db
postgres-user
postgres-password
n8n-encryption-key
```

Use `scripts/seed-keyvault-secrets.sh` as the template. Secret values must come from secure local inputs or the deployment environment and must not be written into Git.

## 3. Deploy the VM application

Copy the following files to `/opt/n8n-project` on the VM:

```text
docker/docker-compose.azure.yml
docker/Caddyfile
dashboard/index.html
scripts/deploy-azure.sh
```

Then run the deployment script with the temporary hostname and Key Vault name. The script retrieves secrets through the VM managed identity, writes a protected runtime environment file, and starts n8n, nginx, and Caddy.

## 4. Verify

```bash
docker compose --env-file /opt/n8n-project/.env.azure \
  -f /opt/n8n-project/docker-compose.azure.yml ps
curl -I https://TEMPORARY_HOSTNAME/
curl -I https://TEMPORARY_HOSTNAME/dashboard/
```

Complete the functional checks in `docs/acceptance-checklist.md`.

## 5. Remove the temporary environment

After the assessment, review the target subscription and run:

```powershell
terraform -chdir=terraform destroy
```

Only run destroy after confirming the resource group and subscription are the intended targets.
