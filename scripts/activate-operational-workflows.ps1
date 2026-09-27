$ErrorActionPreference = 'Stop'
foreach ($file in @('workflows/n8n-workflows.json', 'workflows/n8n-workflows-azure.json')) {
  $workflows = Get-Content $file -Raw | ConvertFrom-Json
  foreach ($workflow in $workflows) {
    if ($workflow.name -in @('01 - Mock Ticket Intake','02 - SLA Reminder Check','03 - Ticket Status Update','04 - Ticket Dashboard API')) {
      $workflow.active = $true
    }
  }
  $workflows | ConvertTo-Json -Depth 100 | Set-Content $file -Encoding UTF8
}
Write-Output 'Operational workflows marked active.'
