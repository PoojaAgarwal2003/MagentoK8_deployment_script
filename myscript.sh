#!/bin/bash

# Define parameters
mysqlAdminLogin=$1
mysqlAdminPassword=$2
storageAccountName=$3
mysqlServerName=$4
storageAccountAccessKey=$5

# Define log file location
logFile="/tmp/myscript.log"

# Function to write output to the log file
write_log() {
    echo "$1" >> "$logFile"
}

# Log the parameters
write_log "MySQL Admin Login: $mysqlAdminLogin"
write_log "MySQL Admin Password: $mysqlAdminPassword"
write_log "Storage Account Name: $storageAccountName"
write_log "MySQL Server Name: $mysqlServerName"
write_log "Storage Account Access Key: $storageAccountAccessKey"

# Add your custom script logic here and write output to the log file
write_log "Script execution started"

# Example script logic
if [ -n "$mysqlAdminLogin" ] && [ -n "$mysqlAdminPassword" ]; then
    write_log "Example logic executed successfully"
else
    write_log "Example logic failed"
fi

write_log "Script execution finished"

# Install Azure CLI if not installed
if ! command -v az &> /dev/null
then
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# Login to Azure CLI using a service principal or managed identity
# Uncomment the below lines if using service principal (replace placeholders with actual values)
# az login --service-principal -u <APP_ID> -p <PASSWORD> --tenant <TENANT_ID>

# Create a temporary container in the storage account (if not exists)
az storage container create --name scripts-logs --account-name "$storageAccountName" --account-key "$storageAccountAccessKey"

# Upload the log file to Azure Blob Storage
az storage blob upload --account-name "$storageAccountName" --account-key "$storageAccountAccessKey" --container-name scripts-logs --file "$logFile" --name myscript.log
