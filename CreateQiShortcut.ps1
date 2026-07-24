function New-QIShortcut {
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$ShortcutName,

        [string]$Description = "Zástupce pro QI Klient",
        [string]$IconLocation = $null
    )

    try {
        if (-not (Test-Path $TargetPath)) {
            return $false
        }

        $publicDesktop = Join-Path $env:PUBLIC "Desktop"
        $shortcutPath  = Join-Path $publicDesktop ("$ShortcutName.lnk")

        $shell    = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)

        $shortcut.TargetPath       = $TargetPath
        $shortcut.WorkingDirectory = Split-Path $TargetPath
        $shortcut.WindowStyle      = 1
        $shortcut.Description      = $Description

        if ($IconLocation) {
            $shortcut.IconLocation = $IconLocation
        }

        $shortcut.Save()
        return $true
    }
    catch {
        return $false
    }
}

New-QIShortcut -TargetPath "C:\QI_client\QI_OSTRA\Client.exe" -ShortcutName "QI Klient"