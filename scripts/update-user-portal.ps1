$p='dashboard/user.html'
$s=Get-Content $p -Raw
$s=$s.Replace("if(j.user)welcome.textContent='Welcome, '+j.user.full_name;else location.href='/login'", "if(!j.user){location.href='/login';return}welcome.textContent='Welcome, '+j.user.full_name;const r=await fetch('/api/tickets',{headers:{Authorization:'Bearer '+t}}),d=await r.json();tickets.innerHTML=d.tickets.length?d.tickets.map(x=>`<p><b>${x.ticket_id}</b> · ${x.title} · ${x.department} · <b>${x.status}</b> · ${x.priority||'Normal'}</p>`).join(''):'<p class=\"muted\">No tickets yet.</p>'")
Set-Content $p $s -NoNewline
