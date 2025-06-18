#!/bin/bash
# setup-azure-db.sh

# Set variables
RESOURCE_GROUP=inspira-project
LOCATION=eastus

# Users database
USERS_DB_SERVER=inspira-users-db
USERS_DB_NAME=users
USERS_DB_USER=users_admin
USERS_DB_PASSWORD=$(openssl rand -base64 16)

# Content database
CONTENT_DB_SERVER=inspira-content-db
CONTENT_DB_NAME=content
CONTENT_DB_USER=content_admin
CONTENT_DB_PASSWORD=$(openssl rand -base64 16)

# Media database
MEDIA_DB_SERVER=inspira-media-db
MEDIA_DB_NAME=media
MEDIA_DB_USER=media_admin
MEDIA_DB_PASSWORD=$(openssl rand -base64 16)

# Create users database server
echo "Creating users database server..."
az postgres flexible-server create \
    --resource-group $RESOURCE_GROUP \
    --name $USERS_DB_SERVER \
    --location $LOCATION \
    --admin-user $USERS_DB_USER \
    --admin-password $USERS_DB_PASSWORD \
    --sku-name Standard_B1ms \
    --tier Burstable \
    --storage-size 32 \
    --version 14 \
    --yes

# Create content database server
echo "Creating content database server..."
az postgres flexible-server create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTENT_DB_SERVER \
    --location $LOCATION \
    --admin-user $CONTENT_DB_USER \
    --admin-password $CONTENT_DB_PASSWORD \
    --sku-name Standard_B1ms \
    --tier Burstable \
    --storage-size 32 \
    --version 14 \
    --yes

# Create media database server
echo "Creating media database server..."
az postgres flexible-server create \
    --resource-group $RESOURCE_GROUP \
    --name $MEDIA_DB_SERVER \
    --location $LOCATION \
    --admin-user $MEDIA_DB_USER \
    --admin-password $MEDIA_DB_PASSWORD \
    --sku-name Standard_B1ms \
    --tier Burstable \
    --storage-size 32 \
    --version 14 \
    --yes

# Create databases
echo "Creating databases..."
az postgres flexible-server db create --resource-group $RESOURCE_GROUP --server-name $USERS_DB_SERVER --database-name $USERS_DB_NAME
az postgres flexible-server db create --resource-group $RESOURCE_GROUP --server-name $CONTENT_DB_SERVER --database-name $CONTENT_DB_NAME
az postgres flexible-server db create --resource-group $RESOURCE_GROUP --server-name $MEDIA_DB_SERVER --database-name $MEDIA_DB_NAME

# Allow access from Azure services
echo "Configuring firewall rules..."
az postgres flexible-server firewall-rule create --resource-group $RESOURCE_GROUP --name $USERS_DB_SERVER --rule-name AllowAllAzureIPs --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
az postgres flexible-server firewall-rule create --resource-group $RESOURCE_GROUP --name $CONTENT_DB_SERVER --rule-name AllowAllAzureIPs --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
az postgres flexible-server firewall-rule create --resource-group $RESOURCE_GROUP --name $MEDIA_DB_SERVER --rule-name AllowAllAzureIPs --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

# Save connection info
echo "Saving connection information to azure-credentials.txt..."
echo "USERS_DB_SERVER=$USERS_DB_SERVER.postgres.database.azure.com" > azure-credentials.txt
echo "USERS_DB_NAME=$USERS_DB_NAME" >> azure-credentials.txt
echo "USERS_DB_USER=$USERS_DB_USER" >> azure-credentials.txt
echo "USERS_DB_PASSWORD=$USERS_DB_PASSWORD" >> azure-credentials.txt
echo "" >> azure-credentials.txt
echo "CONTENT_DB_SERVER=$CONTENT_DB_SERVER.postgres.database.azure.com" >> azure-credentials.txt
echo "CONTENT_DB_NAME=$CONTENT_DB_NAME" >> azure-credentials.txt
echo "CONTENT_DB_USER=$CONTENT_DB_USER" >> azure-credentials.txt
echo "CONTENT_DB_PASSWORD=$CONTENT_DB_PASSWORD" >> azure-credentials.txt
echo "" >> azure-credentials.txt
echo "MEDIA_DB_SERVER=$MEDIA_DB_SERVER.postgres.database.azure.com" >> azure-credentials.txt
echo "MEDIA_DB_NAME=$MEDIA_DB_NAME" >> azure-credentials.txt
echo "MEDIA_DB_USER=$MEDIA_DB_USER" >> azure-credentials.txt
echo "MEDIA_DB_PASSWORD=$MEDIA_DB_PASSWORD" >> azure-credentials.txt

# Update Kubernetes secrets
echo "Updating Kubernetes secrets..."
kubectl create secret generic db-secrets --namespace microservices \
    --from-literal=users-db-url=jdbc:postgresql://$USERS_DB_SERVER.postgres.database.azure.com:5432/$USERS_DB_NAME \
    --from-literal=users-db-user=$USERS_DB_USER \
    --from-literal=users-db-password=$USERS_DB_PASSWORD \
    --from-literal=content-db-url=jdbc:postgresql://$CONTENT_DB_SERVER.postgres.database.azure.com:5432/$CONTENT_DB_NAME \
    --from-literal=content-db-user=$CONTENT_DB_USER \
    --from-literal=content-db-password=$CONTENT_DB_PASSWORD \
    --from-literal=media-db-url=jdbc:postgresql://$MEDIA_DB_SERVER.postgres.database.azure.com:5432/$MEDIA_DB_NAME \
    --from-literal=media-db-user=$MEDIA_DB_USER \
    --from-literal=media-db-password=$MEDIA_DB_PASSWORD \
    --dry-run=client -o yaml | kubectl apply -f -

echo "Database setup complete!" 