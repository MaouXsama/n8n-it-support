$ErrorActionPreference = 'Stop'

$query = @'
SELECT json_build_object(
  'metrics', json_build_object(
    'total_open', COUNT(*) FILTER (WHERE status = 'Open'),
    'networking_open', COUNT(*) FILTER (WHERE status = 'Open' AND department = 'Networking'),
    'helpdesk_open', COUNT(*) FILTER (WHERE status = 'Open' AND department = 'IT Helpdesk'),
    'software_open', COUNT(*) FILTER (WHERE status = 'Open' AND department = 'Software'),
    'networking_total', COUNT(*) FILTER (WHERE department = 'Networking'),
    'helpdesk_total', COUNT(*) FILTER (WHERE department = 'IT Helpdesk'),
    'software_total', COUNT(*) FILTER (WHERE department = 'Software'),
    'completed_today', COUNT(*) FILTER (WHERE status = 'Completed' AND completed_at >= CURRENT_DATE),
    'completed_last_7_days', COUNT(*) FILTER (WHERE status = 'Completed' AND completed_at >= CURRENT_DATE - INTERVAL '7 days'),
    'overdue_open', COUNT(*) FILTER (WHERE status = 'Open' AND due_at <= NOW()),
    'created_today', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE),
    'completed_within_sla', COUNT(*) FILTER (WHERE status = 'Completed' AND completed_at IS NOT NULL AND completed_at <= due_at),
    'completed_after_sla', COUNT(*) FILTER (WHERE status = 'Completed' AND completed_at IS NOT NULL AND completed_at > due_at),
    'sla_compliance_percentage', COALESCE(ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'Completed' AND completed_at <= due_at) / NULLIF(COUNT(*) FILTER (WHERE status = 'Completed'), 0), 1), 0),
    'refreshed_at', NOW()
  ),
  'tickets', COALESCE((
    SELECT json_agg(row_to_json(ticket_rows) ORDER BY ticket_rows.created_at DESC)
    FROM (
      SELECT ticket_id, title, description, requester, department, priority,
             sla_hours, status, classification_status, created_at, due_at, completed_at
      FROM public.tickets
      ORDER BY created_at DESC
      LIMIT 100
    ) ticket_rows
  ), '[]'::json)
) AS dashboard
FROM public.tickets;
'@

foreach ($file in @('workflows/n8n-workflows.json', 'workflows/n8n-workflows-azure.json')) {
  $workflows = Get-Content $file -Raw | ConvertFrom-Json
  $workflow = $workflows | Where-Object { $_.name -eq '04 - Ticket Dashboard API' }
  $node = $workflow.nodes | Where-Object { $_.name -eq 'Execute a SQL query' }
  $node.parameters.query = $query
  $response = $workflow.nodes | Where-Object { $_.name -eq 'Respond to Webhook' }
  $response.parameters.responseBody = '={{ $json.dashboard }}'
  $workflows | ConvertTo-Json -Depth 100 | Set-Content $file -Encoding UTF8
}

Write-Output 'Dashboard API updated with metrics and ticket list.'
