$p='dashboard/login.html'
$s=Get-Content $p -Raw
$s=$s.Replace(' · <a href="/create-ticket">Public ticket form</a>','')
Set-Content $p $s -NoNewline
