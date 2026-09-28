# Masar IT Support Automation Platform

Masar is an internal IT support platform built with n8n, PostgreSQL, Node.js, and a responsive web dashboard. It automates ticket classification, support-team routing, priority assignment, SLA tracking, operational notifications, and role-based ticket management.

## Contents

- [Core capabilities](#core-capabilities)
- [Departments and SLAs](#departments-and-slas)
- [User roles](#user-roles)
- [Ticket lifecycle](#ticket-lifecycle)
- [Email notifications](#email-notifications)
- [Dashboards and appearance](#dashboards-and-appearance)
- [Architecture](#architecture)
- [Workflow exports](#workflow-exports)
- [Local development](#local-development)
- [Azure deployment](#azure-deployment)
- [Security](#security)
- [Project structure](#project-structure)
- [Verification](#verification)

## Core capabilities

- Authenticated account registration and sign-in
- User, department-administrator, and full-administrator access levels
- Ticket submission and personal ticket history
- Automatic support-team classification and routing
- Automatic priority classification
- Manual-review fallback for unrecognized requests
- SLA deadline calculation and monitoring
- Open, In Progress, Completed, and Cancelled ticket states
- Support-team reassignment and administrative status updates
- PostgreSQL ticket, account, notification, and audit storage
- Gmail notifications for account and ticket events
- Operational metrics and SLA performance analytics
- Responsive Masar-branded user and administrator dashboards
- Light, dark, and system appearance modes
- Saudi Arabia timezone display throughout the interface
- Local Docker Compose and Azure deployment configurations

## Departments and SLAs

| Support team | SLA |
|---|---:|
| Networking | 4 hours |
| IT Helpdesk | 2 hours |
| Software | 6 hours |

Requests that cannot be classified confidently are assigned to IT Helpdesk with Normal priority and the `default_manual_review` classification.

## User roles

| Role | Access |
|---|---|
| User | Create tickets, review personal ticket history, view account details, change password, and select an appearance mode |
| Department Administrator | Review and manage tickets assigned to the administrator's department |
| Full Administrator | Review tickets across all departments, reassign support teams, update ticket status, view analytics, and access user information |

Account profile details are read-only. Users can securely change their password after confirming the current password. After a successful password change, the active browser session is cleared after six seconds and the user signs in again with the new password.

## Ticket lifecycle

1. A user submits a title and description through the authenticated portal.
2. n8n classifies the request, assigns a support team and priority, and calculates the SLA deadline.
3. The ticket and its initial notification record are stored in PostgreSQL.
4. The requester and support team receive ticket-creation notifications.
5. Administrators can reassign the support team or change the ticket status.
6. SLA monitoring evaluates both Open and In Progress tickets and sends due-soon and overdue alerts when required.
7. Completion records the completion time and sends the requester a completion notification.

The interface uses **Assigned Team** for the team currently responsible for a ticket, **Department** for an administrator's organizational department, and **Reassign Team** for the administrative routing action.

## Email notifications

Masar uses Gmail through n8n for the following automated notifications:

| Notification | Recipient | Trigger |
|---|---|---|
| Account welcome | User | Successful account registration |
| Password changed | User | Successful password update |
| Ticket received | Requester | New ticket creation |
| New ticket requires review | Support team | New ticket assignment |
| SLA due soon | Support team | Ticket reaches the warning threshold |
| SLA overdue | Support team | Ticket reaches its SLA deadline |
| Ticket completed | Requester | Ticket status changes to Completed |

The email templates use consistent Masar branding, responsive table-based HTML, clear event summaries, ticket details, Saudi Arabia time, and status-specific accent colors. Passwords are never included in email content.

## Dashboards and appearance

The user portal provides ticket creation, personal ticket history, ticket details, account information, password management, and sign-out controls.

Administrator dashboards provide workload summaries, ticket queues, role-appropriate ticket visibility, support-team reassignment, status management, and SLA analytics. Full administrators can work across all departments, while department administrators are limited to their assigned department.

The shared account menu supports Light, Dark, and System appearance preferences. Theme changes affect colors only; card dimensions, spacing, and page structure remain consistent. The selected preference is stored in the browser.

## Architecture

```text
Browser
   |
   v
Caddy HTTPS reverse proxy
   |-- Static Masar dashboard (nginx)
   |-- Authentication and role API (Node.js)
   `-- n8n webhooks and workflow editor
            |
            v
   Azure Database for PostgreSQL

n8n --> Gmail OAuth --> Account and ticket notifications
Azure VM --> Managed Identity --> Azure Key Vault
```

The production services run as containers on an Azure VM. PostgreSQL is provided by Azure Database for PostgreSQL Flexible Server with TLS enabled. Runtime secrets are retrieved through a user-assigned managed identity and Azure Key Vault.

## Workflow exports

The current Azure workflow exports are stored in [`workflows/final-azure/`](workflows/final-azure/).

| Export | Responsibility |
|---|---|
| `0jpOrbi9n4kcGFZT.json` | Ticket intake, classification, routing, persistence, and creation emails |
| `KxtGRf2b9ksw99nr.json` | SLA warning and overdue processing |
| `Etn85v1nMB40Wyhi.json` | Ticket status updates and completion notification |
| `account-welcome.json` | New-account welcome notification |
| `password-changed.json` | Password-change confirmation notification |
| `JgSJa3PxZcMbISoA.json` | Ticket dashboard API |
| `fHZpYNgetCCHtknG.json` | Database setup workflow |
| `kxHV9YI0IfFPqEPH.json` | Manual notification test workflow |

Combined local and Azure-compatible exports are also available in:

- `workflows/n8n-workflows.json`
- `workflows/n8n-workflows-azure.json`

## Local development

### Requirements

- Docker Desktop
- Docker Compose
- PowerShell
- Git
- Terraform, when validating infrastructure changes

Start the local stack from the repository root:

```powershell
docker compose --env-file .env -f .\docker\docker-compose.yml up -d
```

The local n8n editor is available at `http://localhost:5678`. Dashboard source files are served from `dashboard/`, and the authentication API is implemented in `auth-service/`.

Stop the stack with:

```powershell
docker compose --env-file .env -f .\docker\docker-compose.yml down
```

## Azure deployment

Terraform provisions the Azure resource group, virtual machine, networking, PostgreSQL Flexible Server, managed identity, Key Vault, and deployment outputs.

```powershell
cd terraform
terraform init
terraform plan -out n8n.tfplan
terraform apply "n8n.tfplan"
```

After provisioning:

1. Add the required secrets with `scripts/seed-keyvault-secrets.sh`.
2. Copy the Azure deployment files to the VM.
3. Run `scripts/deploy-azure.sh`.
4. Configure the Gmail OAuth credential in n8n using the callback URL displayed by the Gmail credential screen.
5. Import or update the workflows from `workflows/final-azure/`.

The GitHub Actions workflow at `.github/workflows/deploy-azure.yml` deploys changes from `main`. It requires these repository secrets:

- `AZURE_VM_HOST`
- `AZURE_VM_USER`
- `AZURE_SSH_PRIVATE_KEY`

## Security

- Passwords are hashed with bcrypt before storage.
- Authentication uses signed JWT access tokens.
- User and administrator APIs enforce role-based access.
- Department administrators are restricted to their assigned department.
- Password changes require the current password and create an audit record.
- Successful password changes clear the active browser session.
- Azure runtime secrets are stored in Key Vault.
- The Azure VM uses managed identity to retrieve secrets.
- PostgreSQL connections use TLS in Azure.
- Local `.env` files, Terraform state, plans, and private keys must not be committed.
- The deployment workflow does not copy local environment files or Terraform state.

## Project structure

| Path | Purpose |
|---|---|
| `dashboard/` | Login, signup, user portal, administrator dashboard, ticket forms, shared styling, and account controls |
| `auth-service/` | Authentication, authorization, account management, ticket APIs, and audit integration |
| `workflows/` | Local, Azure-compatible, and final n8n workflow exports |
| `docker/` | Local and Azure Compose files plus Caddy configuration |
| `terraform/` | Azure infrastructure definitions |
| `scripts/` | Deployment, maintenance, migration, and operational scripts |
| `docs/` | Architecture, deployment, backup, acceptance, and test documentation |

## Verification

Acceptance checks and recorded test evidence are maintained in:

- [`docs/acceptance-checklist.md`](docs/acceptance-checklist.md)
- [`docs/test-evidence.md`](docs/test-evidence.md)

Additional operational documentation is available in:

- [`docs/architecture.md`](docs/architecture.md)
- [`docs/azure-deployment.md`](docs/azure-deployment.md)
- [`docs/backup-and-recovery.md`](docs/backup-and-recovery.md)
- [`docs/key-vault-secrets.md`](docs/key-vault-secrets.md)
