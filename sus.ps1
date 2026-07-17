Stop-Service -Name BITS, wuauserv -Force
 
Remove-ItemProperty -Name AccountDomainSid, PingID, SusClientId, SusClientIDValidation -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\ -ErrorAction SilentlyContinue
 
Remove-Item "$env:SystemRoot\SoftwareDistribution\" -Recurse -Force -ErrorAction SilentlyContinue
 
Start-Service -Name BITS, wuauserv

(New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()
