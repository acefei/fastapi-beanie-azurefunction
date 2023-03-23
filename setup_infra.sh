#!/bin/bash

# Function app and storage account names must be unique.
project="fastapi-beanie"

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="eastus"
resourceGroup="$project-rg-$randomIdentifier"
tag="create-function-app-connect-to-cosmos-db"
storage="functionsa$randomIdentifier"
functionApp="$project-function-$randomIdentifier"
skuStorage="Standard_LRS"
functionsVersion="4"

# Azure Login
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a storage account for the function app.
echo "Creating $storage"
az storage account create --name $storage --location "$location" --resource-group $resourceGroup --sku $skuStorage

# Create a serverless function app in the resource group.
echo "Creating $functionApp"
az functionapp create --name $functionApp --resource-group $resourceGroup --storage-account $storage --consumption-plan-location "$location" --functions-version $functionsVersion --os-type Linux --runtime python

# Create an Azure Cosmos DB database account using the same function app name.
echo "Creating $functionApp"
az cosmosdb create --name $functionApp --resource-group $resourceGroup

# Get the Azure Cosmos DB connection string.
endpoint=$(az cosmosdb show --name $functionApp --resource-group $resourceGroup --query documentEndpoint --output tsv)
echo $endpoint

key=$(az cosmosdb keys list --name $functionApp --resource-group $resourceGroup --query primaryMasterKey --output tsv)
echo $key

# Configure function app settings to use the Azure Cosmos DB connection string.
az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup --setting CosmosDB_Endpoint=$endpoint CosmosDB_Key=$key
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
