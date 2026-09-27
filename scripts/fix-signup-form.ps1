$p='dashboard/signup.html'
$s=Get-Content $p -Raw
$s=$s.Replace("form.addEventListener('submit',async e=>", "document.getElementById('form').addEventListener('submit',async e=>")
$s=$s.Replace("{full_name:name.value,email:email.value,password:password.value}", "{full_name:document.getElementById('name').value,email:document.getElementById('email').value,password:document.getElementById('password').value}")
$s=$s.Replace("error.textContent=j.message", "document.getElementById('error').textContent=j.message")
Set-Content $p $s -NoNewline
