#This script will setup a Azure DevOps agent with prerequisites to support the ALM Accelerator for Power Platform requirements
#Run this script on a Windows 2019 Server Core by copying the script or using the below powershell command
#To install on your VM run this in PowerShell: iex "& { $(irm https://raw.githubusercontent.com/jenschristianschroder/VM-Configuration/main/aa4pp-devops-agent-vm-setup.ps1) }"
#
# Paramters
#   url
#   token
#   pool
#   agent

param (
    [Parameter(Mandatory=$true)] [String]$url=$(Throw "devops url is mandatory"), 
    [Parameter(Mandatory=$true)] [Security.SecureString]$token=$(Throw "PAT token is mandatory"), 
    [Parameter(Mandatory=$false)] [String]$pool="default", 
    [Parameter(Mandatory=$false)] [String]$agent=""
)


#Download and install PowerShell 7.2.1
Write-Host "Downloading PowerShell 7"
New-Item -Path "$($env:ALLUSERPROFILE)\powershell\7" -ItemType directory
Set-Location -Path "$($env:ALLUSERPROFILE)\powershell\7"
$currentDir = Get-Location
Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v7.2.1/PowerShell-7.2.1-win-x64.zip  -OutFile  "PowerShell-7.2.1-win-x64.zip"
Write-Host "Installing PowerShell 7"
$zipPath = Join-Path -Path $currentDir "PowerShell-7.2.1-win-x64.zip"
Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, "$PWD")
Write-Host "Adding PowerShell 7 to PATH"
$machinePath = [System.Environment]::GetEnvironmentVariable('PATH','Machine')
$machinePathCollection = $machinePath -split ";"
if($machinePathCollection -NOTCONTAINS "$($env:ALLUSERPROFILE)\powershell\7") {
    $machinePath += ";$($env:ALLUSERPROFILE)\PowerShell\7"
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

#TODO Download and install nodejs
#Install-Package npm -RequiredVersion 5.3.0
$npmVersion = "3.5.2"
$npmPath = Join-Path -Path (Get-Location)  "\npm\"
if (!(Test-Path $npmPath)) {
    New-Item -Path "$npmPath" -ItemType directory
}
Install-Package -Name npm -RequiredVersion $npmVersion -Destination "$npmPath" -Force
Write-Host "Adding npm to PATH"
$machinePath = [System.Environment]::GetEnvironmentVariable('PATH','Machine')
$machinePathCollection = $machinePath -split ";"
if($machinePathCollection -NOTCONTAINS "$npmPath\npm.$npmVersion\content\.bin") {
    $machinePath += ";$npmPath\npm.$npmVersion\content\.bin"
    [System.Environment]::SetEnvironmentVariable('PATH', $machinePath, 'Machine')
}
else {
    Write-Host "npm already in PATH"
}



#TODO Download and install jq
#https://www.nuget.org/packages/JQ.NET

#Download and install DevOps Agent
Write-Host "Downloading DevOps Agent"
New-Item -Path "$($env:ALLUSERPROFILE)\agent" -ItemType directory
Set-Location -Path "$($env:ALLUSERPROFILE)\agent"
Invoke-WebRequest -Uri https://vstsagentpackage.azureedge.net/agent/2.195.2/vsts-agent-win-x64-2.195.2.zip  -OutFile  "vsts-agent-win-x64-2.195.2.zip"
Write-Host "Installing DevOps Agent"
Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory("$($env:ALLUSERPROFILE)\agent\vsts-agent-win-x64-2.195.2.zip", "$PWD")
$pat = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token))
write-host $pat
.\config.cmd --unattended --url $url --auth pat --token """$pat""" --pool $pool --agent $agent --acceptTeeEula --runAsService --windowsLogonAccount "NT Authority\\Network Service"

exit 0


