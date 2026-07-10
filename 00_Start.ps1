
#################################################################
# Filip Vyroubal, 2025
#################################################################

# nealokovany prostor na disku

$cdrive = Get-Partition -Driveletter C | Get-Disk
$totalvol = $cdrive.Size
$alls = ($cdrive | Get-Partition | Measure-Object -Property Size -Sum).sum
$unal = ( $totalvol - $alls )

Write-Host ('disk space: ' + [string]( $totalvol / 1024 / 1024 / 1024 ) + ' GB') -BackgroundColor Blue -ForegroundColor Green
$unalspc = $null
if($unal / 1024 / 1024 -gt 100){
    Start-Process -FilePath ".\msgbox.vbs"
    Write-Host ('unalocated: ' + [string]( $unal / 1024 / 1024 ) + ' MB') -BackgroundColor DarkRed -ForegroundColor Yellow
    $unalspc = "jj"
}else{
    Write-Host ('unalocated: ' + [string]( $unal / 1024 / 1024 ) + ' MB') -BackgroundColor Blue -ForegroundColor Green
}

# recovery partition

$rpc = $null
if( ( ( Get-Partition |? { $_.Type -eq 'Recovery' } | Measure-Object ).Count ) -gt 0 ){
    Write-Host "recovery partition: ANO" -BackgroundColor Blue -ForegroundColor Green
}else{
    Write-Host "recovery partition: NE" -BackgroundColor DarkRed -ForegroundColor Yellow
    Start-Process -FilePath ".\msgbox2.vbs"
    $rpc = "nn"
}

$partition4 = Get-Partition |? { $_.Type -eq 'Recovery' }
if ($partition4.PartitionNumber -eq 4 ){
    Write-Host "recovery partition slot 4" -BackgroundColor Blue -ForegroundColor Green
}else{
    Write-Host "recovery partition slot $($partition4.PartitionNumber)" -BackgroundColor DarkRed -ForegroundColor Yellow
    Start-Process -FilePath ".\msgbox5.vbs"
}

if($unalspc -eq "jj"){
    if($rpc -eq $null){
        Remove-Partition -InputObject $partition4
    }
    Resize-Partition -DriveLetter C -Size $(Get-PartitionSupportedSize -DriveLetter C).SizeMax
    Write-Host "you will need to create recovery prtition" -ForegroundColor Blue -BackgroundColor White
}
# kolik je RAM

$ram = ( (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum / 1gb )
Write-Host "RAM: $($ram)" -BackgroundColor Blue -ForegroundColor Green
if(( (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum / 1gb ) -lt 16)
{
    Start-Process -FilePath ".\msgbox4.vbs"
    Write-Host "low ram" -BackgroundColor DarkRed -ForegroundColor Yellow
}

# je vytvoren user saturnin ???

$usr = "saturnin"
$localusr = $null
try{
    Write-Output "finding $($usr)"
    $localusr = Get-LocalUser $usr 
}catch{
    Write-Output "no $($usr)"  
    Start-Process -FilePath ".\msgbox3.vbs"
}
if ($localusr -ceq $null){
    Write-Host "no $($usr)"  -BackgroundColor DarkRed -ForegroundColor Yellow
    Start-Process -FilePath ".\msgbox3.vbs"
    $tmp55 = Read-Host -Prompt "do you want to create saturnin if the next step completes the computer will be nearly unusable y/n"
    if ($tmp55 -ceq "y"){
        New-LocalUser -Name "saturnin"
        Add-LocalGroupMember -Group "Administrators" -Member "saturnin"
    } 
}else{
    Write-Host "$($localusr) was found" -BackgroundColor Blue -ForegroundColor Green
}

# smazani vsech lokalnich uctu mimo "saturnin", Administrator, Guest, DefaultAccount, WDAGUtilityAccount
# Administrator, Guest, DefaultAccount, WDAGUtilityAccount - tyto by meli byt disabled (by default)
$usrs = Get-LocalUser
foreach($user in $usrs)
{
    if($user.name -ceq "saturnin")
    {
        Write-Host "working" -ForegroundColor Blue -BackgroundColor Blue
        
    }elseif ($user.name -ceq "Administrator"){
        Disable-LocalUser -InputObject $user
    }elseif ($user.name -ceq "Guest"){
        Disable-LocalUser -InputObject $user
    }elseif ($user.name -ceq "DefaultAccount"){
        Disable-LocalUser -InputObject $user
    }elseif ($user.name -ceq "WDAGUtilityAccount"){
        Disable-LocalUser -InputObject $user
    }
    else{
        Remove-LocalUser -Name $user.name
    }
}


# je update BIOSu required (jen pro dell optiplex 7010)

#Write-Host "bios update for optiplex 7010 found want to install y/n" -BackgroundColor DarkRed -ForegroundColor Yellow
#$yn = Read-Host -Prompt "y/n"
#if ($yn -ccontains "y"){
#Start-Process -FilePath ".\OptiPlex_7010_1.26.1_SEMB.exe"

#}

# pokud neni recovery partition - moznost spustit jeji vytvoreni

if ($rpc -ceq "nn"){
    Write-Host "create partition y/n" -ForegroundColor Cyan -BackgroundColor Red 
    $yn = Read-Host -Prompt "y/n"
    if ($yn -ccontains "y"){
        .\createRecoveryPartition_local_FV.ps1
    }
}
