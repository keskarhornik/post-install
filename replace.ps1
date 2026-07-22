# Replace the currently installed Windows key with this PC's
# OEM key embedded in UEFI/BIOS, then attempt activation.

# Verify administrative privileges
$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

if (-not $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Write-Error "Run PowerShell as Administrator."
    exit 1
}

Write-Host "Checking the installed Windows edition..." -ForegroundColor Cyan

$Edition = (Get-ComputerInfo -Property WindowsProductName).WindowsProductName
Write-Host "Installed edition: $Edition"

Write-Host "`nLooking for an OEM key embedded in UEFI/BIOS..." -ForegroundColor Cyan

$LicensingService = Get-CimInstance -ClassName SoftwareLicensingService
$FirmwareKey = $LicensingService.OA3xOriginalProductKey

if (:IsNullOrWhiteSpace($FirmwareKey)) {
    Write-Error @"
No embedded OEM product key was found.

This computer might use:
- a digital licence,
- KMS or Active Directory-based activation,
- a MAK key,
- or it might not contain a Windows licence.
"@
    exit 2
}

# Show only the final five characters for identification
$LastFive = $FirmwareKey.Substring($FirmwareKey.Length - 5)
Write-Host "Embedded OEM key found, ending in: $LastFive" -ForegroundColor Green

Write-Host "`nInstalling the destination PC's embedded key..." -ForegroundColor Cyan

$InstallProcess = Start-Process `
    -FilePath "cscript.exe" `
    -ArgumentList @(
        "//NoLogo",
        "$env:windir\system32\slmgr.vbs",
        "/ipk",
        $FirmwareKey
    ) `
    -Wait `
    -PassThru

if ($InstallProcess.ExitCode -ne 0) {
    Write-Error @"
The embedded key could not be installed.

The most likely reason is an edition mismatch. For example:
- Windows Home licence with a Windows Pro image
- Windows Pro licence with a Windows Enterprise image
"@
    exit 3
}

Write-Host "The embedded product key was installed." -ForegroundColor Green
Write-Host "`nAttempting online activation..." -ForegroundColor Cyan

$ActivationProcess = Start-Process `
    -FilePath "cscript.exe" `
    -ArgumentList @(
        "//NoLogo",
        "$env:windir\system32\slmgr.vbs",
        "/ato"
    ) `
    -Wait `
    -
