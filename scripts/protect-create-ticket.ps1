$p='dashboard/create-ticket.html'
$s=Get-Content $p -Raw
$s=$s.Replace('<script>\nconst form=', '<script>\nif(!sessionStorage.getItem("token")){location.href="/login";}const form=')
$s=$s.Replace('<a href="/login">Staff sign in</a>', '<a href="/login">Sign in</a> · <a href="/signup">Sign up</a>')
Set-Content $p $s -NoNewline
