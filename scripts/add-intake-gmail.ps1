$ErrorActionPreference = 'Stop'
$file = 'tmp/intake-routing.json'
$w = Get-Content $file -Raw | ConvertFrom-Json
$nodes = [System.Collections.ArrayList]@($w.nodes)
$existing = @($nodes | Where-Object name -eq 'Send requester creation email') | Select-Object -First 1
if (-not $existing) {
  [void]$nodes.Add([pscustomobject]@{
    parameters = [pscustomobject]@{
      resource = 'message'
      operation = 'send'
      sendTo = '={{ $json.requester }}'
      subject = '=Your IT support ticket {{ $json.ticket_id }} has been created'
      emailType = 'html'
      message = '=Your ticket was received successfully. Ticket ID: {{ $json.ticket_id }}. The IT team will review your request.<br><br>---<br><em>This email was sent automatically with <a href="https://n8n.io">n8n</a></em>'
      options = [pscustomobject]@{}
    }
    type = 'n8n-nodes-base.gmail'
    typeVersion = 2.1
    position = @(672, -240)
    id = 'f0a1b2c3-d4e5-4678-9012-3456789abcde'
    name = 'Send requester creation email'
    credentials = [pscustomobject]@{ gmailOAuth2 = [pscustomobject]@{ id = 'r0i7DQEx6fbebKDM'; name = 'Gmail account' } }
  })
}
$teamExisting = @($nodes | Where-Object name -eq 'Send team notification email') | Select-Object -First 1
if (-not $teamExisting) {
  [void]$nodes.Add([pscustomobject]@{
    parameters = [pscustomobject]@{
      resource = 'message'
      operation = 'send'
      sendTo = 'sda.n8n.project@gmail.com'
      subject = '=New {{ $json.department }} ticket {{ $json.ticket_id }} requires review'
      emailType = 'html'
      message = '=A new ticket has been created.<br><br><b>Ticket ID:</b> {{ $json.ticket_id }}<br><b>Department:</b> {{ $json.department }}<br><b>Priority:</b> {{ $json.priority }}<br><b>SLA:</b> {{ $json.sla_hours }} hours<br><b>Requester:</b> {{ $json.requester }}<br><b>Title:</b> {{ $json.title }}<br><b>Description:</b> {{ $json.description }}<br><br>Please review it in the support dashboard.'
      options = [pscustomobject]@{}
    }
    type = 'n8n-nodes-base.gmail'
    typeVersion = 2.1
    position = @(672, 240)
    id = 'a1b2c3d4-e5f6-4789-0123-456789abcdef'
    name = 'Send team notification email'
    credentials = [pscustomobject]@{ gmailOAuth2 = [pscustomobject]@{ id = 'r0i7DQEx6fbebKDM'; name = 'Gmail account' } }
  })
}
$connections = $w.connections
$connections.'Insert ticket into PostgreSQL'.main = ('{"main":[[{"node":"Prepare Notification","type":"main","index":0}]]}' | ConvertFrom-Json).main
$connections.'Prepare Notification'.main = ('{"main":[[{"node":"Insert the notification record","type":"main","index":0},{"node":"Send requester creation email","type":"main","index":0},{"node":"Send team notification email","type":"main","index":0}]]}' | ConvertFrom-Json).main
Add-Member -InputObject $connections -MemberType NoteProperty -Name 'Send requester creation email' -Value (('{"main":[]}' | ConvertFrom-Json)) -Force
$w.nodes = $nodes
$record = @($w.nodes | Where-Object name -eq 'Insert the notification record') | Select-Object -First 1
if ($record -and $record.parameters.columns.value.channel) { $record.parameters.columns.value.channel = 'gmail' }
$w.connections = $connections
$w | ConvertTo-Json -Depth 100 | Set-Content $file -Encoding UTF8
$w.nodes | ConvertTo-Json -Depth 100 | Set-Content tmp/nodes-only.json -Encoding UTF8
$w.connections | ConvertTo-Json -Depth 100 | Set-Content tmp/connections-only.json -Encoding UTF8
Write-Output 'Gmail creation-email node added.'
