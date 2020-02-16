<#
thrallconstructor.ps1
.DESCRIPTION

    Hyper-V

    Erstellt VMs, VHDs und vSwitche. Kann ausserdem Hyper-V installieren und
    das Problem mit dem Hypervisorschedulertype beheben.
    Dierekte Verbindung zur VM aus dem Menu moeglich.
    
https://github.com/thelamescriptkiddiemax/powershell/Hyper-V
#>
#--- Variablen ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$vmtyp = "2"                                                        # VM-Generation - 1 / 2
$vmpath = "$env:PUBLIC\Documents\Hyper-V\Virtual Machines"          # Speicherort VM
$vhdpath = "$env:PUBLIC\Documents\Hyper-V\Virtual Hard Disks"       # Speicherort VHD
$isopath = "$env:PUBLIC\Documents\Hyper-V\ISOs"                     # Speicherort Installations-ISOs
$switchtyp = "Internal"                                             # Switch-Typ: Internal / Private - Nur gillt nur fuer internen Vswitch
$vmgastdienst = "Gastdienstschnittstelle"                           # Auf deutschem OS Gastdienstschnittstelle / Auf englischem OS Guest Service Interface


#--- Vorbereitung -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$stringhost = [System.String]::Concat("[ ", $env:UserName, " @ ", $env:computername, " @ ", ((Get-WmiObject Win32_ComputerSystem).Domain), " ", (Get-CimInstance Win32_OperatingSystem | Select-Object Caption), ": ", 
((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\" -Name ReleaseID).ReleaseId), " ]   ", (Get-Date -Format "dd/MM/yyyy HH:mm:ss"), "`n", "[ ", $MyInvocation.MyCommand.Name, " ]", "`n","`n") 
$stringhost = $stringhost.replace("{Caption=Microsoft"," ")

Import-Module Hyper-V

$Host.UI.RawUI.BackgroundColor = 'Gray'
$Host.UI.RawUI.ForegroundColor = 'Black'

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Show-Menu
{
    param ([string]$Title = "Muss was getan werden?")
     
    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    
    

    Write-Host " "
	Write-Host " . . .  . . . . . . . . .  $Title  . . . . . . . . .   . . . `n" -ForegroundColor Cyan
    Write-Host "  1 > V-Switch erstellen"
    Write-Host "  2 > VHD erstellen"
    Write-Host "  3 > VM montieren `n"
    Write-Host "------------------------------------------------------------------------------------`n" -ForegroundColor Cyan
    Write-Host "  4 > VM starten und verbinden"
    Write-Host "  5 > PSSession verbinden `n"
    Write-Host "------------------------------------------------------------------------------------`n" -ForegroundColor Cyan
    Write-Host "  6 > Hyper-V-Manager oeffnen"
    Write-Host "  7 > Hyper-V installieren"
    Write-Host "  8 > Hyper-V CPU-Bug fixen `n"
    Write-Host "------------------------------------------------------------------------------------`n" -ForegroundColor Cyan
    Write-Host "  q > Quit `n `n"
    
}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vmmaker ($vmpath, $vhdpath, $vmgastdienst, $vmtyp, $isopath) {
    
    $vswitchall = Get-VMSwitch

    $stringvhdout = [System.String]::Concat("Vorahndene VHDs:`n",(Get-ChildItem -Path $vhdpath | ForEach-Object {$_.BaseName}))
    $stringvswitchout = [System.String]::Concat("Verfuegbare vSwitche:`n", $vswitchall.Name)
    $stringVMerstellt = [System.String]::Concat("   VM ", $vmname, " erstellt!", "`n", "   Snapshots bitte manuell konfigurieren!")

    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    $vmname = Read-Host "  VM-Name?   BSP: Thrall03"
    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    $vmcores = Read-Host "  Wie viele Cores?   BSP: 4"
    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    $vmRAMraw = Read-Host "  VM RAM in GB?   BSP: 16"
    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host $stringvhdout
    $vhdname = Read-Host "  VHD-Name?   BSP: SVR19HD   (NUR VHDX - VHD nicht)"
    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host $stringvswitchout
    $switchName = Read-Host "  vSwitch-Name?   BSP: extVswitch"
    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host "   Montiere VM..."
    Start-Sleep -Seconds 1.5

    $vmpath = [System.String]::Concat($vmpath, "\")
    $vhdpath = [System.String]::Concat($vhdpath, "\", $vhdname, ".vhdx")
    $vmRAM = [System.String]::Concat($vmRAMraw, "GB")
    
    New-VM -Name $vmname -Path $vmpath -MemoryStartupBytes (Invoke-Expression $vmRAM) -VHDPath $vhdpath -SwitchName $switchName -Generation $vmtyp
    Set-VMProcessor -VMName $vmname -Count $vmcores
    Set-VM -Name $vmname  -CheckpointType Disabled
    Enable-VMIntegrationService -name Gast* -VMName $vmname -Passthru
    Enable-VMIntegrationService -VMName $vmname -Name $vmgastdienst

    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host $stringVMerstellt -ForegroundColor DarkRed -BackgroundColor White
    Start-Sleep -Seconds 2

    isodrivemaper $isopath $vmname
    
}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vhdmaker($vhdpath) {
    
    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    $vhdname = Read-Host "   VHD-Name?"
    $vhdsize = Read-Host "   VHD-Groesse?"

    $vhdpath = [System.String]::Concat($vhdpath, "\", $vhdname, ".vhdx")
    $vhdsize = [System.String]::Concat($vhdsize, "GB")
    
    Write-Host "   (F)ixe-, oder (D)ynamische-Groesse? Default - Fix `n"
    $Readhost = Read-Host " ( F / D ) "
    Switch ($ReadHost) 
    {
        F {New-VHD -Path $vhdpath -Fixed -SizeBytes (Invoke-Expression $vhdsize)} 

        D {New-VHD -Path $vhdpath -Dynamic -SizeBytes (Invoke-Expression $vhdsize)}

        Default {New-VHD -Path $vhdpath -Fixed -SizeBytes (Invoke-Expression $vhdsize)} 
    }
    
    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host "   VHD erstellt!"
    Start-Sleep -Seconds 1.5

}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function menu2 {
    
    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host "   (E)xterner-, oder (I)nterner-vSwitch? Default - Extern `n"
    $Readhost = Read-Host " ( E / I ) "
    Switch ($ReadHost) 
        {
            E {extVswitchmaker} 

            I {intVswitchmaker $switchtyp}

            Default {extVswitchmaker} 
        }
}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function intVswitchmaker ($switchtyp) {
    
    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host "   Interner Vswitch"
    $switchName = Read-Host "   vSwitch Name?"
    $switchnotes = Read-Host "   vSwitch Beschreibung?"
    Clear-Host

    New-VMSwitch -Name $switchName -Notes $switchnotes -SwitchType $switchtyp

    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host "   Interner vSwitch erstellt!"
    Start-Sleep -Seconds 1.5
    Clear-Host

}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function extVswitchmaker {
    
    $adapter = Get-NetAdapter

    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host "   Externer Vswitch"

    $menu = @{}
    for ($i=1 ; $i -le $adapter.count ; $i++) 
    { 
    
        Write-Host "$i. $($adapter[$i-1].Name))"
        $menu.Add($i,($adapter[$i-1].Name)) 
 
    }

    [int]$ans = Read-Host "Welche NIC soll der V-Switch nutzen?"
    $selection = $menu.Item($ans)

    $switchnic = $selection

    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    $switchName = Read-Host "   vSwitch Name?"
    $switchnotes = Read-Host "   vSwitch Beschreibung?"
    Clear-Host

    New-VMSwitch -Name $switchName -NetAdapterName $switchnic -AllowManagementOS $true -Notes $switchnotes

    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host "   Externer vSwitch erstellt!"
    Start-Sleep -Seconds 1.5
    Clear-Host

}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function thrallslap {
    
    $vmsalle = Get-VM
    $vmslaufend = Get-VM | Where-Object {$_.State -eq 'Running'}

    $stringvmslocal1 = [System.String]::Concat("    Lokale VMs:", "`n", "     ", $vmsalle, "`n", "    VMs online:", "`n")
    $stringvmslocal2 = [System.String]::Concat("     ", $vmslaufend, "`n")

    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host $stringvmslocal1
    Write-Host $stringvmslocal2-ForegroundColor Yellow
    $vmstartname = Read-Host "   Wer soll dienen?"
    Write-Host $vmstartname -ForegroundColor Green
    Write-Host "   VM (S)tarten, oder (V)erbinden? Default - Starten und verbinden `n"
    $Readhost = Read-Host " ( S / V ) "
    Switch ($ReadHost) 
        {
            S { Start-VM $vmstartname } 

            V { & "C:\windows\System32\vmconnect.exe" localhost $vmstartname }

            Default { Start-VM $vmstartname
                        & "C:\windows\System32\vmconnect.exe" localhost $vmstartname} 
        }
}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function pssstart {
    
    $vmsalle = Get-VM
    $vmslaufend = Get-VM | Where-Object {$_.State -eq 'Running'}

    $stringvmslocal1 = [System.String]::Concat("    Lokale VMs:", "`n", "     ", $vmsalle, "`n", "    VMs online:", "`n")
    $stringvmslocal2 = [System.String]::Concat("     ", $vmslaufend, "`n")

    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host $stringvmslocal1
    Write-Host $stringvmslocal2-ForegroundColor Yellow
    Read-Host "   Ziel-VM?" $vmpss

    Enter-PSSession -VMName $vmpss
    
}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function hypervsetup {
    
    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host "   Installiere Hyper-V. Danach muss das System rebooten!"

    Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
    
}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function isodrivemaper ($isopath, $vmname) {

    $stringisofrage = "  ISO-Name?  BSP: manjaro-xfce-18.1.5-191229-linux54"
    $stringisoout = [System.String]::Concat("Verfuegbare ISOs:`n",(Get-ChildItem -Path $isopath | ForEach-Object {$_.BaseName}))
    $stringvmbereit = [System.String]::Concat("   VM ", $vmname, " bereit zu dienen!")

    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host "   ISO (E)inbinden, oder (S)kippen? Default - Einbinden `n"
    $Readhost = Read-Host " ( E / S ) "
    Switch ($ReadHost) 
    {
        E       {Write-Host $stringisoout
                $isoname = Read-Host $stringisofrage
                $isopath = [System.String]::Concat($isopath, "\", $isoname, ".iso")
                Add-VMDvdDrive -VMName $vmname -Path $isopath}

        S       { Write-Host "Keine ISO eingebunden"; Start-Sleep -Seconds 1.5}

        Default {Write-Host $stringisoout
                $isoname = Read-Host $stringisofrage
                $isopath = [System.String]::Concat($isopath, "\", $isoname, ".iso")
                Add-VMDvdDrive -VMName $vmname -Path $isopath} 
    }

    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host $stringvmbereit
    Start-Sleep -Seconds 2

}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function hypervcpufix {
    
    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host "   WAS? Hyper-V kann deine Cores nicht managen???!!1!??" -ForegroundColor DarkRed -BackgroundColor Black
    Write-Host "   ....das fixen wir... Aber dein System braucht danach einen Reboot."

    bcdedit /set hypervisorschedulertype Classic

    Clear-Host
    Write-Host $stringhost -ForegroundColor Magenta
    Write-Host "   System Reboot" -ForegroundColor DarkRed -BackgroundColor Black
    Write-Host "   Druecke Enter wenn Du bereit bist" -ForegroundColor Yellow -BackgroundColor Black
    
    Pause
    
    Restart-Computer

}
#--- Verarbeitung -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Clear-Host
Write-Host $stringhost -ForegroundColor Magenta
Write-Host "  ThrallConstructor `n" -ForegroundColor Yellow
Write-Host "  Pfade in Scriptvariablen anpassen!" -ForegroundColor DarkRed -BackgroundColor White
Start-Sleep -Seconds 3


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
do{
     Show-Menu
     $input = Read-Host "Aufgabe?"
     switch ($input)
     {
        1 { menu2 }                                                         # Aktion Taste 1 - vSwitch-Menu
        2 { vhdmaker $vhdpath }                                             # Aktion Taste 2 - VHDs erstellen
		3 { vmmaker $vmpath $vhdpath $vmgastdienst $vmtyp $isopath }        # Aktion Taste 3 - VMs montieren
		4 { thrallslap }                                                    # Aktion Taste 4 - VM starten und verbinden
        5 { pssstart }                                                      # Aktion Taste 5 - PSSession starten
        6 { virtmgmt.msc }                                                  # Aktion Taste 6 - Hyper-V-Manager oeffnen
        7 { hypervsetup }                                                   # Aktion Taste 7 - Hyper-V installieren
        8 { hypervcpufix }                                                  # Aktion Taste 8 - Hyper-V CPU
     }
}
until ($input -eq 'q') 
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Clear-Host
Write-Host $stringhost -ForegroundColor Magenta
Write-Host "   ThrallConstructor `n" -ForegroundColor Yellow
Start-Sleep -Seconds 3

