$p = 'dashboard/login.html'
$s = Get-Content $p -Raw
$s = $s.Replace("location.href='/dashboard'", "location.href='/dashboard/'")
Set-Content $p $s -NoNewline
