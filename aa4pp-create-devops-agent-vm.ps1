# This script will provision a Virtual Machine in Azure, install prerequisites for running a DevOps agent for ALM Accelerator for Power Platform and install and configure a DevOps agent to run as a Windows Service.
#   VM Image: 2019-datacenter-core-g2
#   Installed prerequisites, PowerShell 7.2.1, nuget
#   DevOps agent: vsts-agent-win-x64-2.195.2
# Parameters:
#   tenant (Mandatory): the tenant in which to create the VM
#   subscription (Mandatory): the subscription in which to create the VM
#   resourceGroup (Optional, Default: AA4pp-DevOps-Agent): the resource group in which to create the VM
#   location (Otional, Default: centralus): the location of the resource group
#   vmName (Optional, Default: AA4PP-agent): the name of the VM
#   adminUserName (Mandatory): the administrator username for the VM
#   adminPassword (Mandatory): the administrator password for the VM. adminPassword must be of type SecureString
#   url (Mandatory): the url for the DevOps account (https://dev.azure.com/[account])
#   token (Mandatory): the Personal Access Token for the agent to connect to DevOps. token must be of type SecureString
#   pool (Optional, Default: Default): the Agent Pool that the agent will run in
#   agent (Optional, Default: $vmName): the name of the DevOps agent

Param (
    [Parameter(Mandatory=$true)] [String]$tenant=$(Throw "tenant id is mandatory"),
    [Parameter(Mandatory=$true)] [String]$subscription=$(Throw "subscription id is mandatory"),
    [Parameter(Mandatory=$false)] [String]$resourceGroup="AA4PP-DevOps-Agent", 
    [Parameter(Mandatory=$false)] [String]$location="centralus", 
    [Parameter(Mandatory=$false)] [String]$vmName="AA4PP-agent",
    [Parameter(Mandatory=$true)] [String]$adminUserName=$(Throw "admin username is mandatory"),
    [Parameter(Mandatory=$true)] [Security.SecureString]$adminPassword=$(Throw "admin password is mandatory"),
    [Parameter(Mandatory=$true)] [String]$url=$(Throw "devops url is mandatory"), 
    [Parameter(Mandatory=$true)][Security.SecureString]$token=$(Throw "PAT token is mandatory"), 
    [Parameter(Mandatory=$false)] [String]$pool="Default", 
    [Parameter(Mandatory=$false)] [String]$agent=""
)

az account clear

# Login to Azure
Write-Host "Logging in to Azure"
az login --use-device-code #--tenant $tenant ### something messed up using device code!?

# Set subscription
Write-Host "Setting subscription"
az account set --subscription $subscription

# Create Resource Group
Write-Host "Creating resource group ($resourceGroup)"
if ((az group exists --name $resourceGroup) -eq "false") {
    az group create --name $resourceGroup --location $location
}
else {
    Write-Host "Resource group already exist"
}

# Create VM
Write-Host "Provisioning VM ($vmName)"
$adminpwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword))
az vm create --resource-group $resourceGroup --name $vmName --image MicrosoftWindowsServer:WindowsServer:2019-datacenter-core-g2:latest --public-ip-sku Standard --admin-username $adminUserName --admin-password """$adminpwd"""

Write-Host "VM provisioning complete"

# Run aa4pp-install-devops-agent.ps1 on VM
Write-Host "Download setup script for DevOps agent and prerequisites for ALM Accelerator for Power Platform"
az vm run-command invoke --command-id RunPowerShellScript --name $vmName -g $resourceGroup --scripts 'irm https://raw.githubusercontent.com/jenschristianschroder/AA4PP-DevOps-Agent/main/aa4pp-install-devops-agent.ps1 | Out-File aa4pp-install-devops-agent.ps1'
Write-Host "Installing DevOps agent and prerequisites for ALM Accelerator for Power Platform"
az vm run-command invoke --command-id RunPowerShellScript --name $vmName -g $resourceGroup --scripts @aa4pp-install-devops-agent.ps1 --parameters "url=$url token=$token pool=$pool agent=$agent"

# Log out
az account clear
az logout

# Complete
Write-Host "Provioning and setup complete"
Write-Host "VM will restart now and agent will connect to $url on start"

# Reboot
#Restart-Computer