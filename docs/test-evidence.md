# Test Evidence

This document records the functional checks completed during the local and Azure build.

## Routing and SLA results

| Test | Result |
|---|---|
| Networking ticket | Routed to Networking, SLA 4 hours, automatic classification |
| IT Helpdesk ticket | Routed to IT Helpdesk, SLA 2 hours, automatic classification |
| Software ticket | Routed to Software, SLA 6 hours, automatic classification |
| Unknown ticket | Routed to IT Helpdesk, SLA 2 hours, `default_manual_review` |

## Notification results

- Initial mock notification was stored as `sent` for the correct department team.
- The 15-minute SLA warning was stored as `sent`.
- The due-time reminder was stored as `sent`.

## Completion result

- A ticket status update changed the ticket to `Completed`.
- `completed_at` was recorded.

## Dashboard result

The dashboard API returned open totals, per-department totals, completed-today, completed-last-seven-days, overdue-open, and created-today metrics.

## Deployment result

- Terraform validation passed.
- Azure VM, managed PostgreSQL, Key Vault, managed identity, networking, and temporary hostname were provisioned.
- The Azure n8n endpoint and dashboard returned HTTP 200.
- Azure production intake, status update, dashboard, and SLA checks passed.
