# Internal IT Ticket Automation Platform

An n8n-based internal IT ticket automation platform with automatic department routing, SLA tracking, real Gmail notifications, PostgreSQL persistence, and professional user/admin dashboards.

## Departments and SLAs

| Department | SLA |
|---|---:|
| Networking | 4 hours |
| IT Helpdesk | 2 hours |
| Software | 6 hours |

Unknown requests are routed to IT Helpdesk with Normal priority and `default_manual_review` classification.

## Features

- Authenticated user ticket intake through an n8n webhook
- Automatic department classification
- Automatic priority classification
- SLA deadline calculation
- 15-minute SLA warning
- Due-time reminder
- PostgreSQL ticket and notification storage
- Gmail requester confirmation and team notification
- Gmail 15-minute and due-time SLA reminders
- Gmail completion notification
- Ticket completion updates
- Dashboard metrics API and web dashboard
- User signup, login, ticket submission, and ticket history
- Full-admin and department-admin role-based access
- Department reassignment and status updates
- Saudi Arabia timezone display in the UI
- Local Docker Compose deployment
- Azure VM deployment with managed PostgreSQL
- Azure Key Vault secret management
- Caddy HTTPS reverse proxy

## Workflow Files

- `00 - Database Setup`
- `01 - Ticket Intake`
- `02 - SLA Reminder Check`
- `03 - Ticket Status Update`
- `04 - Ticket Dashboard API`

The local export is in `workflows/n8n-workflows.json`. The Azure-compatible export is in `workflows/n8n-workflows-azure.json`.

## Local Requirements

- Docker Desktop
- Docker Compose
- PowerShell
- Git
- Terraform

## Local Startup

```powershell
docker compose --env-file .env -f .\docker\docker-compose.yml up -d
```

n8n: `http://localhost:5678`

Local dashboard files are in `dashboard/`; the production dashboard is served by the Azure Caddy container.

For local development, start the stack and open n8n at `http://localhost:5678`. The Azure dashboard is available at the temporary hostname created by Terraform.

## Azure Deployment

Terraform creates the `n8n-project` resource group, East US VM, networking, temporary Azure hostname, PostgreSQL server in its configured separate region, managed identity, and Key Vault.

```powershell
cd terraform
terraform init
terraform plan -out n8n.tfplan
terraform apply "n8n.tfplan"
```

After deployment, add the required Key Vault secrets using `scripts/seed-keyvault-secrets.sh`, copy the Azure deployment files to the VM, and run `scripts/deploy-azure.sh`. Configure the Gmail OAuth credential in n8n using the callback URL shown in the Gmail credential screen.

## Security and Scope Notes

- Secrets are stored in Azure Key Vault for the Azure deployment.
- Terraform variables, state, plan files, and local `.env` files must not be committed.
- SSH is intentionally open for the temporary assessment environment; restrict it before any long-term production use.
- The Azure deployment uses a temporary Azure hostname rather than a purchased domain.
- PostgreSQL has seven-day backup retention and storage auto-grow enabled.
- The Azure environment is temporary and should be reviewed before long-term use.

## Verification

The final acceptance checks are documented in `docs/acceptance-checklist.md`. Test evidence is recorded in `docs/test-evidence.md`.

## Project Status

The application is deployed and operational on Azure. The final workflow exports are stored in `workflows/final-azure/`, and the public source repository is:

`https://github.com/MaouXsama/n8n-it-support`

The GitHub Actions deployment completed successfully. The live system uses Azure PostgreSQL, Azure Key Vault, n8n, the authentication service, the Masar-branded dashboards, and Gmail OAuth notifications.

## Important Files

- `dashboard/` — user, admin, login, signup, and ticket pages
- `auth-service/` — authentication and role-based API service
- `workflows/` — local and Azure n8n workflow exports
- `docker/` — local and Azure Compose/Caddy configuration
- `terraform/` — Azure infrastructure definitions
- `docs/` — architecture, deployment, backup, and acceptance documentation

## Project Completion Status

The project implementation and Azure deployment are complete.

### Completed

- Azure resource group `n8n-project` created.
- Azure VM deployed in East US.
- PostgreSQL deployed in its configured separate region.
- Azure temporary hostname configured.
- HTTPS reverse proxy configured with Caddy.
- Azure Key Vault and managed identity configured.
- PostgreSQL credentials, n8n encryption key, and authentication JWT secret stored in Key Vault.
- Local and Azure Docker Compose deployments configured.
- n8n workflows created, activated, and exported.
- PostgreSQL database schema configured.
- User signup, login, logout, and ticket history implemented.
- Full administrator and department administrator accounts implemented.
- Role-based access and department-based ticket visibility tested.
- Ticket creation, automatic routing, priority classification, and manual-review fallback implemented.
- Networking SLA configured for 4 hours.
- IT Helpdesk SLA configured for 2 hours.
- Software SLA configured for 6 hours.
- Ticket reassignment and Open, In Progress, and Completed statuses implemented.
- Ticket completion timestamps and details popup implemented.
- Status and priority colors implemented.
- Saudi Arabia timezone display implemented.
- Full-admin, department-admin, and user dashboards implemented.
- In-progress dashboard metrics implemented.
- Masar branding, logo, login, signup, and responsive page designs implemented.
- Requester creation email configured with Gmail.
- Team notification email configured with Gmail.
- SLA warning and due-time reminder emails configured with Gmail.
- Ticket completion email configured with Gmail.
- Gmail OAuth credential connected and tested.
- Final health, routing, permissions, SLA, email, and dashboard tests completed.
- Temporary test tickets and mock notification records removed.
- Terraform validation, outputs, and Key Vault references verified.
- Complete project committed and pushed to GitHub.
- GitHub Actions deployment workflow added and tested successfully.

### Remaining Delivery Evidence

- Capture final screenshots.
- Prepare the final demonstration.
- Compare the system with the original project brief.
- Assemble the final handover package.

## GitHub Actions Deployment

The workflow in `.github/workflows/deploy-azure.yml` deploys changes from `main` to the Azure VM. Configure these repository secrets before enabling it:

- `AZURE_VM_HOST` — VM hostname or public IP
- `AZURE_VM_USER` — SSH username
- `AZURE_SSH_PRIVATE_KEY` — private SSH key matching the VM's authorized public key

The workflow never copies `.env.azure`, Terraform state, Terraform plans, or local temporary files. Azure secrets remain on the VM and are managed through Key Vault.
