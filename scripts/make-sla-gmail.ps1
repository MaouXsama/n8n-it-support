$ErrorActionPreference='Stop'
$all=Get-Content 'tmp/azure-workflows-fixed-v4.json' -Raw|ConvertFrom-Json
$w=@($all|Where-Object name -eq '02 - SLA Reminder Check')|Select-Object -First 1
$sql=@'
WITH candidates AS (
  SELECT t.ticket_id,t.department,t.department || ' Team' AS recipient_group,
    'SLA warning: ticket ' || t.ticket_id || ' is due within 15 minutes.' AS message
  FROM tickets t WHERE t.status='Open' AND t.due_at>NOW() AND t.due_at<=NOW()+INTERVAL '15 minutes'
    AND NOT EXISTS (SELECT 1 FROM notifications n WHERE n.ticket_id=t.ticket_id AND n.message LIKE 'SLA warning:%')
  UNION ALL
  SELECT t.ticket_id,t.department,t.department || ' Team' AS recipient_group,
    'SLA due: ticket ' || t.ticket_id || ' has reached its deadline and is still open.' AS message
  FROM tickets t WHERE t.status='Open' AND t.due_at<=NOW()
    AND NOT EXISTS (SELECT 1 FROM notifications n WHERE n.ticket_id=t.ticket_id AND n.message LIKE 'SLA due:%')
), inserted AS (
  INSERT INTO notifications(ticket_id,department,recipient_group,message,channel,status)
  SELECT ticket_id,department,recipient_group,message,'gmail','sent' FROM candidates
  RETURNING ticket_id,department,recipient_group,message,channel,status
)
SELECT * FROM inserted;
'@
$n=@($w.nodes|Where-Object name -eq 'Execute a SQL query')|Select-Object -First 1
$n.parameters.query=$sql
$nodes=[System.Collections.ArrayList]@($w.nodes)
[void]$nodes.Add([pscustomobject]@{parameters=[pscustomobject]@{resource='message';operation='send';sendTo='sda.n8n.project@gmail.com';subject='=IT support SLA reminder: {{ $json.ticket_id }}';emailType='html';message='=<b>{{ $json.message }}</b><br><br>Department: {{ $json.department }}<br>Team: {{ $json.recipient_group }}';options=[pscustomobject]@{}};type='n8n-nodes-base.gmail';typeVersion=2.1;position=@(480,0);id='b2c3d4e5-f607-4890-1234-56789abcdef0';name='Send SLA reminder email';credentials=[pscustomobject]@{gmailOAuth2=[pscustomobject]@{id='r0i7DQEx6fbebKDM';name='Gmail account'}}})
$w.nodes=$nodes
Add-Member -InputObject $w.connections -MemberType NoteProperty -Name 'Execute a SQL query' -Value (('{"main":[[{"node":"Send SLA reminder email","type":"main","index":0}]]}'|ConvertFrom-Json)) -Force
$w|ConvertTo-Json -Depth 100|Set-Content tmp/sla-gmail-workflow.json -Encoding UTF8
$w.nodes|ConvertTo-Json -Depth 100|Set-Content tmp/sla-nodes.json -Encoding UTF8
$w.connections|ConvertTo-Json -Depth 100|Set-Content tmp/sla-connections.json -Encoding UTF8
Write-Output 'SLA Gmail workflow prepared.'
