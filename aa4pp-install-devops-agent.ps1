#This script will setup a Azure DevOps agent with prerequisites to support the ALM Accelerator for Power Platform requirements
#Run this script on a Windows 2019 Server Core by copying the script or using the below powershell command
#To install on your VM run this in PowerShell: iex "& { $(irm https://raw.githubusercontent.com/jenschristianschroder/VM-Configuration/main/aa4pp-devops-agent-vm-setup.ps1) }"

param ($url, $token, $pool="default", $agent="")

if ($url -eq $null) {
    Write-Host "DevOps url not supplied. Exiting"
    exit 1
}
if ($token -eq $null) {
    Write-Host "Personal access token not supplied. Exiting"
    exit 1
}


#Download and install PowerShell 7.2.1
Write-Host "Downloading PowerShell 7"
Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v7.2.1/PowerShell-7.2.1-win-x64.msi  -OutFile  "$HOME\Downloads\PowerShell-7.2.1-win-x64.msi"
Write-Host "Installing PowerShell 7"
$msi = "$HOME\Downloads\PowerShell-7.2.1-win-x64.msi"
Start-Process $msi -argumentlist "/passive /norestart" -wait
Write-Host "Adding PowerShell 7 to PATH"
$machinePath = [System.Environment]::GetEnvironmentVariable('PATH','Machine')
$machinePathCollection = $machinePath -split ";"
if($machinePathCollection -NOTCONTAINS "c:\program files\powershell\7") {
    $machinePath += ";C:\Program Files\PowerShell\7"
    [System.Environment]::SetEnvironmentVariable('PATH', $machinePath, 'Machine')
}
else {
    Write-Host "PowerShell 7 already in PATH"
}

#Download and install nuget
Write-Host "Downloading nuget"
$Version = "latest"

$NuGetFolder = "$($env:ALLUSERPROFILE)/.nuget/cli/$Version"
$NuGetPath = "$NuGetFolder/nuget.exe"
if (!(Test-Path $NuGetPath -PathType Leaf)) {
    if (!(Test-Path $NuGetPath -PathType Container)) {
        New-Item -type Directory -Path $NuGetFolder | Out-Null
    }
    Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/$Version/nuget.exe" -OutFile $NuGetPath
}
Write-Host "Adding nuget to PATH"
$machinePath = [System.Environment]::GetEnvironmentVariable('PATH','Machine')
$machinePathCollection = $machinePath -split ";"
if($machinePathCollection -NOTCONTAINS "$NuGetFolder") {
    $machinePath += ";$NuGetFolder"
    [System.Environment]::SetEnvironmentVariable('PATH', $machinePath, 'Machine')
}
else {
    Write-Host "nuget already in PATH"
}

#Download and install DevOps Agent
Write-Host "Downloading DevOps Agent"
Invoke-WebRequest -Uri https://vstsagentpackage.azureedge.net/agent/2.195.2/vsts-agent-win-x64-2.195.2.zip  -OutFile  "$HOME\Downloads\vsts-agent-win-x64-2.195.2.zip"
Write-Host "Installing DevOp"
New-Item -Path .\agent -ItemType directory
Set-Location -Path .\agent
Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory("$HOME\Downloads\vsts-agent-win-x64-2.195.2.zip", "$PWD")
.\config.cmd --unattended --url $url --auth pat --token $token --pool $pool --agent $agent --acceptTeeEula --runAsService --windowsLogonAccount "NT Authority\\Network Service"

#Reboot
Restart-Computer


