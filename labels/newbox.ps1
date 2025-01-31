
<#
# Description: Boxstarter Script for dev on Windows 11
# Author: Darrell Taylor <darrell@realgo.com>
# Last Updated: 2023-11-16
#
# Save this as devSetup.ps1, then run on Administrator powershell with :
#   >Set-ExecutionPolicy RemoteSigned
#   >. { iwr -useb https://boxstarter.org/bootstrapper.ps1 } | iex; Get-Boxstarter -Force
#   >Install-BoxstarterPackage -PackageName devSetup.ps1 -DisableReboots
#       you can remove the -DisableReboots if you want to allow reboot, boxstarter will pick up where it left off

# References:
# https://gist.github.com/comigor/9fd1f0b7a1add1ae3ebaef535008e654
# https://github.com/bltavares/windows-devbox/blob/master/install.ps1
# https://gist.github.com/mrichards42/fa7eb6dbb5994855552a1d964d4754de
# https://gist.github.com/NickCraver/7ebf9efbfd0c3eab72e9
# https://gist.github.com/jessfraz/7c319b046daa101a4aaef937a20ff41f
# https://gist.github.com/zloeber/9c2d659a2a8f063af26c9ba0285c7e78
#>


#------------------------------------------------------------------------------
# Create empty folders
#------------------------------------------------------------------------------

# https://github.com/mwrock/boxstarter/issues/241#issuecomment-336028348
New-Item -Path "c:\temp" -ItemType directory -Force | Out-Null
New-Item -Path "c:\tools" -ItemType directory -Force | Out-Null
New-Item -Path "c:\work" -ItemType directory -Force | Out-Null
New-Item -Path "c:\work\projects" -ItemType directory -Force | Out-Null
New-Item -Path "c:\work\builds" -ItemType directory -Force | Out-Null
New-Item -Path "c:\work\logs" -ItemType directory -Force | Out-Null


#------------------------------------------------------------------------------
# First, ensure windows is up to date
#------------------------------------------------------------------------------
Enable-MicrosoftUpdate
#this will install  updates, it can take a long time, does not work rn
#Install-WindowsUpdate 


#------------------------------------------------------------------------------
# TEMPORARY
#------------------------------------------------------------------------------
Disable-UAC

#------------------------------------------------------------------------------
# Uninstall unnecessary applications that come with Windows out of the box
#------------------------------------------------------------------------------
#DISABLE All BLOATWARE EXCEPT STORE, this is not great since we want to keep WSL
#Get-AppxPackage -AllUsers | where-object {$_.name –notlike "*store*"} | Remove-AppxPackage


# To list store apps: Get-AppxPackage | sort -property Name | Select-Object Name, PackageFullName, Version | Format-Table -AutoSize

# Remove junk
function removeApp {
    Param ([string]$appName)
    Write-Output "Trying to remove $appName"
    Get-AppxPackage $appName -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where DisplayNam -like $appName | Remove-AppxProvisionedPackage -Online
}

$applicationList = @(
    "*MarchofEmpires*"
    "*Autodesk*"
    "*BubbleWitch*"
    "*garden*"
    "*hidden*"
    "*deezer*"
    "*phototastic*"
    "*tunein*"
    "king.com*"
    "G5*"
    "*Facebook*"
    "*Keeper*"
    "*.EclipseManager"
    "ActiproSoftwareLLC.562882FEEB491" # Code Writer
    "*DolbyAccess*"
    "*disney*"
    "*HiddenCityMysteryofShadows*"
    "*Dell*"
    "*Dropbox*"
    "*Facebook*"
    "*Keeper*"
    "*McAfee*"
    "*Xbox*"
    "*Twitter*"
    "*outlook*"
    "*onenote*"
    "Microsoft.*advertising*"
    "Microsoft.*3D*"
    "Microsoft.Bing*"
    "Microsoft.Getstarted"
    "Microsoft.Messaging"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftStickyNotes"
    "Microsoft.Music*"
    "Microsoft.Office.OneNote"
    "Microsoft.Office.Sway"
    "Microsoft.OneConnect"
    "Microsoft.People"
    "Microsoft.SkypeApp"
    "Microsoft.Wallet"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsSoundRecorder"
    "microsoft.windowscommunicationsapps"
    "Microsoft.Zune*"
    "MicrosoftTeams"
);

foreach ($app in $applicationList) {
    removeApp $app
}

# Uninstall McAfee Security App
$mcafee = gci "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { gp $_.PSPath } | ? { $_ -match "McAfee Security" } | select UninstallString
if ($mcafee) {
    $mcafee = $mcafee.UninstallString -Replace "C:\Program Files\McAfee\MSC\mcuihost.exe",""
    Write "Uninstalling McAfee..."
    start-process "C:\Program Files\McAfee\MSC\mcuihost.exe" -arg "$mcafee" -Wait
}


#------------------------------------------------------------------------------
# Windows Settings
#------------------------------------------------------------------------------

try {
    Update-ExecutionPolicy Unrestricted
    Set-WindowsExplorerOptions -showHiddenFilesFoldersDrives -showProtectedOSFiles -showFileExtensions
    Enable-RemoteDesktop

	## Opens PC to This PC, not quick access
	Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1

	## Disable Quick Access: Recent Files
	# Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name ShowRecent -Type DWord -Value 0

	## Disable Quick Access: Frequent Folders
	# Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name ShowFrequent -Type DWord -Value 0

	## Dock
	Set-BoxstarterTaskbarOptions -Size Small -Dock Left -Combine Always -AlwaysShowIconsOn -MultiMonitorOn -MultiMonitorMode All -MultiMonitorCombine Always

	## Privacy: Let apps use my advertising ID: Disable	
	If (-Not (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {	
	    New-Item -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo | Out-Null	
	}	
	Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo -Name Enabled -Type DWord -Value 0	

	## Privacy: SmartScreen Filter for Store Apps: Disable	
	Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost -Name EnableWebContentEvaluation -Type DWord -Value 0	

	## WiFi Sense: HotSpot Sharing: Disable	
	If (-Not (Test-Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting")) {	
	    New-Item -Path HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting | Out-Null	
	}	
	Set-ItemProperty -Path HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting -Name value -Type DWord -Value 0	

	## WiFi Sense: Shared HotSpot Auto-Connect: Disable	
	Set-ItemProperty -Path HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots -Name value -Type DWord -Value 0	

	## Start Menu: Disable Bing Search Results	
	Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name BingSearchEnabled -Type DWord -Value 0	

	## Turn off People in Taskbar	
	If (-Not (Test-Path "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People")) {	
	    New-Item -Path HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People | Out-Null	
	}	
	Set-ItemProperty -Path "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name PeopleBand -Type DWord -Value 0


    # Hide useless folders
    gi "$Home\3D Objects",$Home\Contacts,$Home\Favorites,$Home\Links,"$Home\Saved Games",$Home\Searches -Force | foreach { $_.Attributes = $_.Attributes -bor "Hidden" }
    # To Restore:
    #gi "$Home\3D Objects",$Home\Contacts,$Home\Favorites,$Home\Links,"$Home\Saved Games",$Home\Searches -Force | foreach { $_.Attributes = $_.Attributes -xor "Hidden" }
} catch {}

#------------------------------------------------------------------------------
# Software
#------------------------------------------------------------------------------

# Better Console,  not working?
cinst microsoft-windows-terminal

# Git
choco install -y -package-parameters "'/GitAndUnixToolsOnPath /WindowsTerminal /NoAutoCrlf'" git 

# WSL
If (-Not(Get-Command "wsl" -errorAction SilentlyContinue)){
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    wsl --set-default-version 2
    # ubuntu will ask for a password, so install it manually later
    # wsl --install -d ubuntu

    #WSL subsysstem,  I think this is the old way of installing it.  kept for refrence
    #cinst Containers -source windowsfeatures
    #cinst Microsoft-Windows-Subsystem-Linux -source windowsfeatures
}

#Need putty for pagent and ssh
cinst putty.install -y

# set up git to use pagent/putty for ssh
[Environment]::SetEnvironmentVariable("GIT_SSH", "C:\Program Files\PuTTY\plink.exe", "Machine")
#fork is a gui for git
cinst git-fork -y

# Refresh
Update-SessionEnvironment #refreshing env due to Git install
RefreshEnv

#set a timeserver
w32TM /config /syncfromflags:manual /manualpeerlist:time.google.com
w32tm /config /update
w32tm /resync


#####################
# SOFTWARE
#####################

# 7Zip
cinst 7zip.install -y

# Some browsers
cinst GoogleChrome -y
cinst firefox -y

#Plugins and Runtime
#cinst javaruntime -y
# we use amazon corretto jdk 11
cinst corretto11jdk -y

# editors 
choco install vim -y
cinst vscode -y

# misc tools
cinst postman -y

# install node version manager, though gradle handles most node stuff
cinst nvm -y

# Messaging
cinst slack -y

# windows tools
cinst powertoys -y
cinst sysinternals -y

#clink will add persistant history to windows cmd.exe
cinst clink-maintained -y

# Graphic Tools
cinst paint.net -y



#python
choco install python311 --params "/InstallDir:C:\tools\python"


cinst arduino -y
cinst foxitreader
cinst treesizefree
cinst vlc.install
cinst brave
cinst inkscape
cinst youtube-dl
cinst qgis
cinst kicad
cinst wget
cinst dbeaver
cinst blender
cinst tuxpaint
#------------------------------------------------------------------------------
# Set up env vars
#------------------------------------------------------------------------------

# set up git to use pagent/putty for ssh
[Environment]::SetEnvironmentVariable("GIT_SSH", "C:\Program Files\PuTTY\plink.exe", "Machine")

# Refresh
Update-SessionEnvironment #refreshing env due to Git install
RefreshEnv

#------------------------------------------------------------------------------
# Restore Temporary Settings
#------------------------------------------------------------------------------
Enable-UAC


$msg = 'Do you want generate an SSH key? [y/n]'
$response = Read-Host -Prompt $msg
if ($response -eq 'y') {
    echo "Select RSA and make sure you use a passphrase for your private key."
    puttygen.exe | Out-Null
}


if (-Not(Get-Process pageant -ErrorAction SilentlyContinue)) {
    pageant.exe --keylist 
    $msg = 'Add your SSH key to pagent and then press any key'
    $response = Read-Host -Prompt $msg
}


$msg = 'Do you want to clone projects? [y/n]'
$response = Read-Host -Prompt $msg
if ($response -eq 'y') {

#need to connect to https://github.com/ at least once to get public keys before using git
putty github.com

cd C:\work\projects\

