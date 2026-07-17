# Get the process IDs of the services and kill them instantly
Get-CimInstance -ClassName Win32_Service -Filter "Name in ('BITS', 'wuauserv')" | 
    ForEach-Object { 
        if ($_.ProcessId -gt 0) { 
            Stop-Process -Id $_.ProcessId -Force 
        } 
    }
 
Remove-ItemProperty -Name AccountDomainSid, PingID, SusClientId, SusClientIDValidation -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\ -ErrorAction SilentlyContinue
 
Remove-Item "$env:SystemRoot\SoftwareDistribution\" -Recurse -Force -ErrorAction SilentlyContinue
 
Start-Service -Name BITS, wuauserv

(New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()
