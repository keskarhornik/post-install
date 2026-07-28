# 1. Stop Windows Update and BITS services
Stop-Service -Name wuauserv, bits -Force

# 2. Remove SusClientId and related registry entries
$UpdatePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate"
Remove-ItemProperty -Path $UpdatePath -Name SusClientId, SusClientIDValidation, AccountDomainSid, PingID -ErrorAction SilentlyContinue

# 3. (Optional) Wipe the SoftwareDistribution folder cache
Remove-Item "$env:SystemRoot\SoftwareDistribution\" -Recurse -Force -ErrorAction SilentlyContinue

# 4. Restart update services
Start-Service -Name wuauserv, bits

# 5. Force authorization reset to generate the NEW SusClientId
wuauclt.exe /resetauthorization /detectnow
wuauclt.exe /reportnow

# 6. Trigger a modern scan (Windows 10 / 11 / Server 2016+)
usoclient StartScan