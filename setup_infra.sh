#!/bin/bash

# Function app and storage account names must be unique.
project="fastapi-beanie"

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="eastus"
resourceGroup="$project-rg-$randomIdentifier"
tag="create-function-app-connect-to-cosmos-db"
storage="functionsa$randomIdentifier"
account="$project-cosmos-$randomIdentifier"
database="azure-function-app"
collection="fastapi-beanie"
serverVersion="4.0"
functionApp="$project-function-$randomIdentifier"
skuStorage="Standard_LRS"
functionsVersion="4"

prepare() {
    # Azure Login
    az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID > /dev/null
}

new() {
    # Create a resource group
    echo "Creating rg $resourceGroup in "$location"..."
    az group create --name $resourceGroup --location "$location" --tags $tag

    # Create a storage account for the function app.
    echo "Creating sa $storage"
    az storage account create --name $storage --location "$location" --resource-group $resourceGroup --sku $skuStorage

    # Create a serverless function app in the resource group.
    echo "Creating fa $functionApp"
    az functionapp create --name $functionApp --resource-group $resourceGroup --storage-account $storage --consumption-plan-location "$location" --functions-version $functionsVersion --os-type Linux --runtime python

    # Create a Cosmos account for MongoDB API
    echo "Creating cosmos $functionApp"
    az cosmosdb create --name $functionApp --resource-group $resourceGroup --kind MongoDB --server-version $serverVersion

    # Create a MongoDB API database
    echo "Creating database $database"
    az cosmosdb mongodb database create --account-name $account --resource-group $resourceGroup --name $database

    # Create a MongoDB API collection
    echo "Creating collection $collection"
    az cosmosdb mongodb collection create --account-name $account --resource-group $resourceGroup --database-name $database --name $collection --throughput 400

    # Get the Azure Cosmos DB connection string.
    endpoint=$(az cosmosdb show --name $functionApp --resource-group $resourceGroup --query documentEndpoint --output tsv)
    echo $endpoint

    key=$(az cosmosdb keys list --name $functionApp --resource-group $resourceGroup --query primaryMasterKey --output tsv)
    echo $key

    # Configure function app settings to use the Azure Cosmos DB connection string.
    az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup --setting CosmosDB_Endpoint=$endpoint CosmosDB_Key=$key
}

upd() {
    read -p "Please enter resource group name: " rg
    read -p "Please enter function app to associate newly plan: " func_app

    functionapp_plan="DedicatedPlan$RANDOM"
    echo "Create a new app service plan"
    az functionapp plan create --name "$functionapp_plan" --resource-group "$rg" --sku B1 --is-linux true
    echo "Move your existing Function App to the newly created plan"
    az functionapp update --plan "$functionapp_plan" -n "$func_app" --resource-group "$rg"
}

del() {
    read -p "Please enter resource group name" rg
    echo "Deleting $rg with all resources"
    az group delete --name $rg -y
}

prepare
case "$1" in
    new)  echo "New Azure Function Env"
        new
        ;;
    upd)  echo  "Upgrade the service plan to Dedicated Plan"
        upd
        ;;
    del)  echo  "Delele all resources"
        del
        ;;
    *) echo "Invalid action $1, please run bash $0 [new/del/upd]"
    ;;
esac
