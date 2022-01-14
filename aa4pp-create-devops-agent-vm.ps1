Param ($tenant, $resourceGroup, $location, $vmName, $adminUserName, [Security.SecureString]$adminPassword, $url, $token, $pool="default", $agent="")

if ($tenant -eq $null) {
    $tenant = Read-Host -Prompt "Please enter the tenant id" 
}
if ($subscription -eq $null) {
    $subscription = Read-Host -Prompt "Please enter the subscription id"
}
if ($resourceGroup -eq $null) {
    $resourceGroup = Read-Host -Prompt "Please enter name for the resource group in which the VM will be created"
}
if ($location -eq $null) {
    $location = Read-Host -Prompt "Please enter the location of the resource group"
}
if ($vmName -eq $null) {
    $vmName = Read-Host -Prompt "Please enter name of the VM" -
}
if ($adminUserName -eq $null) {
    $adminUserName = Read-Host -Prompt "Please enter the VM admin username"
}
if ($adminPassword -eq $null) {
    $adminPassWord = Read-Host -Prompt "Please enter the VM admin password (minimum 12 characters, 1 digit, 1 uppercase, 1 special character)" -AsSecureString
}
if ($url -eq $null) {
    $url = Read-Host -Prompt "Please enter a your devops org url (https://dev.azure.com/[your org])" 
}
if ($token -eq $null) {
    $token = Read-Host -Prompt "Please enter the personal access token that the devops agent will use to connect" -AsSecureString
}


# Login to Azure
az login --tenant $tenant --use-device-code --allow-no-subscriptions

# Set subscription
az account set --subscription $subscription

# Create Resource Group
az group create --name $resourceGroup --location $location

# Create VM
az vm create --resource-group $resourceGroup --name $vmName --image MicrosoftWindowsServer:WindowsServer:2019-datacenter-core-g2:latest --public-ip-sku Standard --admin-username $adminUserName --admin-password $adminPassword

# Run aa4pp-install-devops-agent.ps1 on VM
az vm run-command invoke  --command-id RunPowerShellScript --name $vmName -g $resourceGroup --scripts 'iex "& { $(irm https://raw.githubusercontent.com/jenschristianschroder/AA4PP-DevOps-Agent/main/aa4pp-devops-agent-vm-setup.ps1) } -url=$url -token=$token -pool=$pool -agent=$agent"' 