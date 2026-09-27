$ErrorActionPreference = 'Stop'

$priorityCode = @'
let priority = 'Normal';
if (/(security incident|security breach|company-wide outage|production outage|production down|production unavailable|multiple users affected|everyone affected)/.test(text)) {
  priority = 'Critical';
} else if (/(cannot access|can't access|unable to access|blocked|unavailable|urgent|vpn not working|vpn down|will not start|won't start|cannot start|not responding)/.test(text)) {
  priority = 'High';
} else if (/(forgot my password|access request|installation request|install|need access|minor|general request|new keyboard)/.test(text)) {
  priority = 'Low';
}
'@

foreach ($file in @('workflows/n8n-workflows.json', 'workflows/n8n-workflows-azure.json')) {
  $workflows = Get-Content $file -Raw | ConvertFrom-Json

  foreach ($workflow in $workflows) {
    $setup = @($workflow.nodes | Where-Object { $_.name -eq 'Execute a SQL query' -and $workflow.name -eq '00 - Database Setup' }) | Select-Object -First 1
    if ($setup) {
      $setup.parameters.query = $setup.parameters.query -replace "department VARCHAR\(50\) NOT NULL,", "department VARCHAR(50) NOT NULL,`n    priority VARCHAR(20) NOT NULL DEFAULT 'Normal',"
      if ($setup.parameters.query -notmatch 'ADD COLUMN IF NOT EXISTS priority') {
        $setup.parameters.query += "`nALTER TABLE tickets ADD COLUMN IF NOT EXISTS priority VARCHAR(20) NOT NULL DEFAULT 'Normal';"
      }
    }

    if ($workflow.name -eq '01 - Mock Ticket Intake') {
      $code = @($workflow.nodes | Where-Object { $_.name -eq 'Code' }) | Select-Object -First 1
      if ($code) {
        if ($code.parameters.jsCode -notmatch 'const ticketId') {
          $idBlock = @'

const ticketId = $json.ticket_id && $json.ticket_id !== 'null'
  ? $json.ticket_id
  : `T-${Date.now().toString().slice(-8)}`;
'@
          $code.parameters.jsCode = $code.parameters.jsCode -replace 'const text = .*?;\r?\n', ('$0' + $idBlock)
          $code.parameters.jsCode = $code.parameters.jsCode -replace '    \.\.\.\$json,', "    ...`$json,`n    ticket_id: ticketId,"
        }
      }
      if ($code -and $code.parameters.jsCode -notmatch "let priority") {
        $code.parameters.jsCode = $code.parameters.jsCode -replace "const dueAt =", "$priorityCode`nconst dueAt ="
        $code.parameters.jsCode = $code.parameters.jsCode -replace "    department,\r?\n", "    department,`n    priority,`n"
      }

      $insert = @($workflow.nodes | Where-Object { $_.name -eq 'Insert ticket into PostgreSQL' }) | Select-Object -First 1
      if ($insert.parameters.query) {
        $insert.parameters.query = $insert.parameters.query -replace "department, sla_hours", "department, priority, sla_hours"
        if ($insert.parameters.query -match 'priority' -and $insert.parameters.query -notmatch '\$json\.priority') {
          $insert.parameters.query = $insert.parameters.query.Replace("  '{{ `$json.department }}',", "  '{{ `$json.department }}',`n  '{{ `$json.priority }}',")
        }
      }
      if ($insert.parameters.columns.value -and -not $insert.parameters.columns.value.priority) {
        $insert.parameters.columns.value | Add-Member -NotePropertyName priority -NotePropertyValue "={{ `$json.priority }}"
      }
    }
  }

  $workflows | ConvertTo-Json -Depth 100 | Set-Content $file -Encoding UTF8
}

Write-Output 'Workflow exports updated with automatic priority and schema migration.'
