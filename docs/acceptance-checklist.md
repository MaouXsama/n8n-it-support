# Acceptance Checklist

## Infrastructure

- [ ] Terraform validates successfully.
- [ ] Resource group `n8n-project` exists in East US.
- [ ] VM is running with Docker and Caddy installed.
- [ ] PostgreSQL Flexible Server exists in Canada Central.
- [ ] Key Vault and managed identity are configured.
- [ ] PostgreSQL backup retention is configured.

## n8n Workflows

- [ ] Database setup creates `tickets` and `notifications`.
- [ ] Networking requests receive a 4-hour SLA.
- [ ] IT Helpdesk requests receive a 2-hour SLA.
- [ ] Software requests receive a 6-hour SLA.
- [ ] Unknown requests route to IT Helpdesk with manual-review classification.
- [ ] Department notification records are created.
- [ ] Ticket completion updates status and completion time.
- [ ] 15-minute warning notification is created.
- [ ] Due-time notification is created.
- [ ] Dashboard metrics return correct counts.

## Access and Deployment

- [ ] n8n is accessible through the temporary HTTPS hostname.
- [ ] Dashboard is accessible at `/dashboard/`.
- [ ] PostgreSQL secrets are loaded from Key Vault.
- [ ] Azure workflow export is preserved in the repository.
- [ ] GitHub Actions passes validation and deployment checks.
- [ ] Terraform state handling is documented.

## Evidence

Record test ticket IDs, outputs, screenshots, and any known temporary-scope limitations before final submission.
