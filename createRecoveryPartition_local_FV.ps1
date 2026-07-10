clear

function vyrblLocal-desifrovatDisk {
    Write-Host 'Vypinam bitLocker.' -ForegroundColor blue -BackgroundColor yellow
    ( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + ' Vypinam bitlocker.' ) | Out-File $logFile -Append -Encoding ascii
    Disable-BitLocker -MountPoint c:
}

function vyrblLocal-zasifrovatDisk {
    Write-Host 'Zapinam bitLocker.' -ForegroundColor red -BackgroundColor yellow
    ( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + ' Zapinam bitlocker.' ) | Out-File $logFile -Append -Encoding ascii
    Enable-BitLocker -MountPoint c: -RecoveryPasswordProtector -UsedSpaceOnly
    return 'restartuj'
}

function vyrblLocal-beziDesifrovani {
    $hotovo = 100 - ( Get-BitLockerVolume -MountPoint c: ).EncryptionPercentage
    #Write-Host ('Probiha desifrovani disku - zbyva '+ $zbyva +' %') -ForegroundColor red -BackgroundColor yellow
    Write-Progress -Activity "Probiha desifrovani disku" -Status "$hotovo%" -PercentComplete $hotovo
}

function vyrblLocal-beziSifrovani {
    $hotovo = ( Get-BitLockerVolume -MountPoint c: ).EncryptionPercentage
    #Write-Host ('Probiha sifrovani disku - hotovo '+ $hotovo +' %') -ForegroundColor red -BackgroundColor yellow
    Write-Progress -Activity "Probiha sifrovani disku" -Status "$hotovo%" -PercentComplete $hotovo
}

function vyrblLocal-cekaniPartition {
    do{
        Start-Sleep -Milliseconds 100
    }while( ( Get-Partition |? { $_.Type -eq 'Recovery' } | Measure-Object ).Count -eq 0 )
    Write-Host 'Recovery partition vytvorena.' -ForegroundColor red -BackgroundColor yellow
    ( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + ' Recovery partition vytvorena.' ) | Out-File $logFile -Append -Encoding ascii
    #.\_test.ps1
}

function vyrblLocal-cekaniDesifrovani {
    do{
        Start-Sleep -Seconds 1
        vyrblLocal-beziDesifrovani
    }while( ( ( Get-BitLockerVolume -MountPoint c: ).VolumeStatus ) -ne 'FullyDecrypted' )
    ( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + ' Svazek je fully decrypted.' ) | Out-File $logFile -Append -Encoding ascii
}

function vyrblLocal-cekaniSifrovani {
    do{
        Start-Sleep -Seconds 1
        vyrblLocal-beziSifrovani
    }while( ( ( Get-BitLockerVolume -MountPoint c: ).VolumeStatus ) -ne 'FullyEncrypted' )
    ( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + ' Svazek je fully encrypted.' ) | Out-File $logFile -Append -Encoding ascii
}

function vyrblLocal-vytvoritRecoveryPartition {
    Write-Host 'Vytvarim recovery partition.' -ForegroundColor red -BackgroundColor yellow
    ( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + ' Vytvarim recovery partition.' ) | Out-File $logFile -Append -Encoding ascii

    $newSize = ( Get-Partition -DriveLetter C ).Size - 1073741824 # zmenseni o 1 GB
    if( $newSize -gt ( Get-PartitionSupportedSize -DriveLetter C ).SizeMin ){

        Resize-Partition -DriveLetter C -Size $newSize
        $diskNumber = ( Get-Partition |? { $_.DriveLetter -eq 'C' } ).DiskNumber
        New-Partition -DiskNumber $diskNumber -UseMaximumSize -GptType "{de94bba4-06d1-4d40-a16a-bfd50179d6ac}"

        # Re-enable Windows Recovery Environment
        reagentc /enable

    }else{
        Write-Host 'Sem se recovery partition nevejde.' -ForegroundColor red -BackgroundColor yellow
    }
}

function vyrblLocal-hotovo {
    Write-Host '*************************' -ForegroundColor red -BackgroundColor green
    Write-Host '*        HOTOVO         *' -ForegroundColor red -BackgroundColor green
    Write-Host '* recovery partition OK *' -ForegroundColor red -BackgroundColor green
    Write-Host '*   disk je encrypted   *' -ForegroundColor red -BackgroundColor green
    Write-Host '*************************' -ForegroundColor red -BackgroundColor green
    ( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + ' HOTOVO: Recovery partition OK, svazek je fully encrypted' ) | Out-File $logFile -Append -Encoding ascii
    return 'hotovo'
}

##############################

$winreFileName = 'Winre.wim'
#$winreFilePath = '\\dmczfsisd01.dmcz.emea.denso\install\_MS\MS_Windows\MS_W10\Recovery'
$winreFilePath = $PSScriptRoot
$winreSource = $winreFilePath + '\' + $winreFileName
$winreDestinationFolder = 'C:\Windows\System32\Recovery\'
$winreDestinationFile = $winreDestinationFolder + $winreFileName

##############################

$logFile = $env:USERPROFILE + '\Desktop\recoveryPartition.txt'

if( ( ( Get-Partition |? { $_.Type -eq 'Recovery' } | Measure-Object ).Count ) -eq 0 ){
    # neni recovery partition
    if( -not ( Test-Path -Path $winreDestinationFile ) ){
        # chybi soubor Winre.wim
        Write-Host 'Kopiruji soubor Winre.wim' -ForegroundColor red -BackgroundColor yellow
        ( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + ' Kopiruji soubor Winre.wim' ) | Out-File $logFile -Append -Encoding ascii
        #New-PSDrive -Name source -PSProvider FileSystem -Root $winreFilePath -Credential ( Get-Credential )
        Copy-Item -Path $winreSource -Destination $winreDestinationFolder
        #Remove-PSDrive source
    }else{
        Write-Host 'Soubor Winre.wim je pritomen.' -ForegroundColor red -BackgroundColor yellow
        ( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + ' Soubor Winre.wim je pritomen.' ) | Out-File $logFile -Append -Encoding ascii
    }
}

if( ( Get-Partition |? { $_.Type -eq 'Recovery' } | Measure-Object ).Count -eq 0 ){

    # neni recovery partition
    Write-Host 'Neni recovery partition.' -ForegroundColor red -BackgroundColor yellow
    ( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + ' Neni recovery partition.' ) | Out-File $logFile -Append -Encoding ascii

    if( ( ( Get-BitLockerVolume -MountPoint c: ).VolumeStatus ) -eq 'FullyEncrypted' ){

        # je zasifrovano => desifrovat
        $return = vyrblLocal-desifrovatDisk

        # cekani az bude desifrovano
        $return = vyrblLocal-cekaniDesifrovani

    }
    if( ( ( Get-BitLockerVolume -MountPoint c: ).VolumeStatus ) -eq 'DecryptionInProgress' ){

        # cekani az bude desifrovano
        $return = vyrblLocal-cekaniDesifrovani

    }
    if( ( ( Get-BitLockerVolume -MountPoint c: ).VolumeStatus ) -eq 'FullyDecrypted' ){

        # vytvoreni recovery partition
        $return = vyrblLocal-vytvoritRecoveryPartition

        # cekani
        $return = vyrblLocal-cekaniPartition

        # zasifrovat disk
        #$return = vyrblLocal-zasifrovatDisk

    }
    if( ( ( Get-BitLockerVolume -MountPoint c: ).VolumeStatus ) -eq 'EncryptionInProgress' ){

        # sifrovani
        $return = vyrblLocal-beziSifrovani
        Write-Host '... ale je to divne, protoze neni recovery partition.' -ForegroundColor red -BackgroundColor yellow
        ( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + ' ... ale je to divne, protoze neni recovery partition.' ) | Out-File $logFile -Append -Encoding ascii
    }

}else{

    # je recovery partition
    Write-Host 'Tady uz recovery partition je.' -ForegroundColor red -BackgroundColor yellow
    ( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + ' Tady uz recovery partition je.' ) | Out-File $logFile -Append -Encoding ascii

    if( ( ( Get-BitLockerVolume -MountPoint c: ).VolumeStatus ) -eq 'FullyDecrypted' ){

        # je odsifrovano => zasifrovat
        #$return = vyrblLocal-zasifrovatDisk

    }
    if( ( ( Get-BitLockerVolume -MountPoint c: ).VolumeStatus ) -eq 'EncryptionInProgress' ){

        # cekani az bude zasifrovano
        $return = vyrblLocal-cekaniSifrovani

    }
    if( ( ( Get-BitLockerVolume -MountPoint c: ).VolumeStatus ) -eq 'FullyEncrypted' ){
        $return = vyrblLocal-hotovo
    }
}

# zapnuti bitlockeru => je potreba restart
if( $return -eq 'restartuj' ){

    Write-Host 'Restartuji...' -ForegroundColor red -BackgroundColor yellow
    ( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + ' Restartuji...' ) | Out-File $logFile -Append -Encoding ascii

    Restart-Computer

}

if( $return -eq 'hotovo' ){
    ( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + ' HOTOVO: Recovery partition OK, svazek je fully encrypted' ) | Out-File $logFile -Append -Encoding ascii
    #( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + "`tOK`t$computerName" ) | Out-File $logFileMain -Append -Encoding ascii
}else{
    #( ( Get-Date -Format 'yyyy-MM-dd HH:mm:ss' ) + "`tERR`t$computerName" ) | Out-File $logFileMain -Append -Encoding ascii
}
