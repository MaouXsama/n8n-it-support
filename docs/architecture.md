# Architecture

## Local development

```text
Browser / PowerShell
        |
        v
  n8n container :5678
        |
        v
 PostgreSQL container :5432
        |
        v
   Docker named volumes
```

The local environment uses Docker Compose. n8n stores workflow data in PostgreSQL, while the ticket workflows store tickets and mock notifications in the same database.

## Azure deployment

```text
Internet
   |
Temporary Azure DNS hostname + HTTPS
   |
Azure VM (East US)
   |-- Caddy reverse proxy :443
   |-- n8n container       127.0.0.1:5678
   `-- Dashboard nginx     127.0.0.1:8080
        |
        v
Azure Database for PostgreSQL Flexible Server (Canada Central)
```

The VM uses a user-assigned managed identity to read runtime secrets from Azure Key Vault. PostgreSQL is not deployed inside the VM's Docker Compose stack in Azure; it is an Azure-managed service with TLS enabled, seven-day backup retention, and storage auto-grow.

## Workflow responsibilities

| Workflow | Responsibility |
|---|---|
| 00 - Database Setup | Creates the ticket and notification tables when run manually |
| 01 - Mock Ticket Intake | Receives, classifies, calculates SLA, stores, and mocks the initial notification |
| 02 - SLA Reminder Check | Sends the 15-minute warning and due-time reminder |
| 03 - Ticket Status Update | Marks tickets completed and records completion time |
| 04 - Ticket Dashboard API | Returns dashboard metrics |

## Brief alignment

- n8n is the automation engine.
- PostgreSQL is the persistence layer.
- Terraform provisions Azure infrastructure.
- Key Vault stores Azure runtime secrets.
- The dashboard exposes operational ticket metrics.
- Department routing is automatic for Networking, IT Helpdesk, and Software.
- Unknown requests use IT Helpdesk and `default_manual_review`.
- The dashboard form collects requester details and issue information; department, priority, and SLA are assigned by n8n.
- Requesters receive creation and completion emails. Departments receive assignment and SLA escalation notifications.
