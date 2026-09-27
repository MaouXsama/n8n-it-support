$ErrorActionPreference = 'Stop'
$file = 'workflows/n8n-workflows-azure.json'
$workflows = Get-Content $file -Raw | ConvertFrom-Json
$workflow = @($workflows | Where-Object name -eq '01 - Mock Ticket Intake') | Select-Object -First 1
$code = @($workflow.nodes | Where-Object name -eq 'Code') | Select-Object -First 1
$code.parameters.jsCode = @'
const title = String($json.title || '').toLowerCase();
const description = String($json.description || '').toLowerCase();
const text = `${title} ${description}`;
const ticketId = $json.ticket_id && $json.ticket_id !== 'null' ? $json.ticket_id : `T-${Date.now().toString().slice(-8)}`;

const rules = [
  ['Networking', ['cannot connect to vpn','vpn not working','vpn down','vpn','wireless network','wi-fi','wifi','router','switch','firewall','dns','internet','network','connection']],
  ['IT Helpdesk', ['forgot my password','password','account','login','log in','sign in','printer','laptop','keyboard','mouse','email']],
  ['Software', ['application crashes','software','application','app','bug','error','microsoft office','install','program']]
];
let department = 'IT Helpdesk';
let matchedKeyword = null;
for (const [name, keywords] of rules) {
  const match = keywords.find((keyword) => text.includes(keyword));
  if (match) { department = name; matchedKeyword = match; break; }
}

let priority = 'Normal';
if (/(security incident|security breach|company-wide outage|production outage|production down|production unavailable|multiple users affected|everyone affected)/.test(text)) priority = 'Critical';
else if (/(cannot access|can't access|unable to access|blocked|unavailable|urgent|vpn not working|vpn down|will not start|won't start|cannot start|not responding)/.test(text)) priority = 'High';
else if (/(forgot my password|access request|installation request|install|need access|minor|general request|new keyboard)/.test(text)) priority = 'Low';

const slaHours = { Networking: 4, 'IT Helpdesk': 2, Software: 6 };
return { json: { ...$json, ticket_id: ticketId, department, priority, sla_hours: slaHours[department], due_at: new Date(Date.now() + slaHours[department] * 3600000).toISOString(), classification_keyword: matchedKeyword, classification_status: matchedKeyword ? 'automatic' : 'default_manual_review' } };
'@
$workflows | ConvertTo-Json -Depth 100 | Set-Content $file -Encoding UTF8
Write-Output 'Local Azure workflow export updated.'
