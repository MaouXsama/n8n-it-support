$p='dashboard/user.html';$s=Get-Content $p -Raw
$s=$s.Replace('<p>Submit and track your IT support tickets.</p>', '<p>Submit and track your IT support tickets.</p><button id="signout">Sign out</button>')
$s=$s.Replace('<script>const token=', '<script>document.getElementById("signout").addEventListener("click",()=>{sessionStorage.clear();location.href="/login"});const token=')
Set-Content $p $s -NoNewline
