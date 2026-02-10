#!/bin/bash

# Azure Deployment Script for Car Price Prediction App
# This script automates the deployment process to Azure App Service

set -e  # Exit on error

echo "=========================================="
echo "🚗 Car Price Predictor - Azure Deployment"
echo "=========================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="car-price-predictor-rg"
LOCATION="eastus"
APP_NAME="car-price-predictor-${RANDOM}"
PLAN_NAME="car-price-predictor-plan"
PYTHON_VERSION="3.13"

echo -e "${BLUE}Configuration:${NC}"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  App Name: $APP_NAME"
echo "  Plan Name: $PLAN_NAME"
echo "  Python Version: $PYTHON_VERSION"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed!${NC}"
    echo "Please install it from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

echo -e "${GREEN}✅ Azure CLI is installed${NC}"
echo ""

# Login to Azure
echo -e "${BLUE}Step 1: Logging in to Azure...${NC}"
az login || {
    echo -e "${RED}❌ Failed to login to Azure${NC}"
    exit 1
}
echo -e "${GREEN}✅ Successfully logged in${NC}"
echo ""

# List available subscriptions
echo -e "${BLUE}Available subscriptions:${NC}"
az account list --output table
echo ""

# Ask user to confirm subscription
read -p "Is the default subscription correct? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    read -p "Enter subscription ID: " subscription_id
    az account set --subscription "$subscription_id"
    echo -e "${GREEN}✅ Subscription set${NC}"
fi
echo ""

# Create resource group
echo -e "${BLUE}Step 2: Creating resource group...${NC}"
az group create --name $RESOURCE_GROUP --location $LOCATION --output table || {
    echo -e "${RED}❌ Failed to create resource group${NC}"
    exit 1
}
echo -e "${GREEN}✅ Resource group created${NC}"
echo ""

# Create App Service plan
echo -e "${BLUE}Step 3: Creating App Service plan...${NC}"
echo "Select pricing tier:"
echo "  1) Free (F1) - For testing"
echo "  2) Basic (B1) - For small production (~\$13/month)"
echo "  3) Standard (S1) - For production (~\$70/month)"
read -p "Enter choice (1-3): " tier_choice

case $tier_choice in
    1) SKU="F1" ;;
    2) SKU="B1" ;;
    3) SKU="S1" ;;
    *) SKU="B1" ;;
esac

az appservice plan create \
    --name $PLAN_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --is-linux \
    --sku $SKU \
    --output table || {
    echo -e "${RED}❌ Failed to create App Service plan${NC}"
    exit 1
}
echo -e "${GREEN}✅ App Service plan created${NC}"
echo ""

# Create web app
echo -e "${BLUE}Step 4: Creating Web App...${NC}"
az webapp create \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --plan $PLAN_NAME \
    --runtime "PYTHON:$PYTHON_VERSION" \
    --output table || {
    echo -e "${RED}❌ Failed to create Web App${NC}"
    exit 1
}
echo -e "${GREEN}✅ Web App created${NC}"
echo ""

# Configure app settings
echo -e "${BLUE}Step 5: Configuring app settings...${NC}"
SECRET_KEY=$(openssl rand -hex 32)

az webapp config appsettings set \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --settings \
        SCM_DO_BUILD_DURING_DEPLOYMENT=true \
        SECRET_KEY="$SECRET_KEY" \
        WEBSITE_HTTPLOGGING_RETENTION_DAYS=7 \
    --output table

az webapp config set \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --startup-file "gunicorn --bind=0.0.0.0:8000 --timeout 600 --workers 2 app:app" \
    --output table
echo -e "${GREEN}✅ App settings configured${NC}"
echo ""

# Enable HTTPS only
echo -e "${BLUE}Step 6: Enabling HTTPS...${NC}"
az webapp update \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --https-only true \
    --output table
echo -e "${GREEN}✅ HTTPS enabled${NC}"
echo ""

# Deploy code
echo -e "${BLUE}Step 7: Deploying code...${NC}"
echo "Select deployment method:"
echo "  1) Deploy from current directory (ZIP)"
echo "  2) Setup Git deployment"
read -p "Enter choice (1-2): " deploy_choice

case $deploy_choice in
    1)
        echo "Creating deployment package..."
        zip -r deploy.zip . -x "*.git*" -x "*__pycache__*" -x "*.pkl" -x "deploy.zip" > /dev/null 2>&1
        
        echo "Deploying..."
        az webapp deployment source config-zip \
            --name $APP_NAME \
            --resource-group $RESOURCE_GROUP \
            --src deploy.zip
        
        rm deploy.zip
        echo -e "${GREEN}✅ Code deployed${NC}"
        ;;
    2)
        az webapp deployment source config-local-git \
            --name $APP_NAME \
            --resource-group $RESOURCE_GROUP \
            --output table
        
        DEPLOY_URL=$(az webapp deployment source show \
            --name $APP_NAME \
            --resource-group $RESOURCE_GROUP \
            --query "repoUrl" -o tsv)
        
        echo -e "${GREEN}✅ Git deployment configured${NC}"
        echo ""
        echo "Add remote and push:"
        echo "  git remote add azure $DEPLOY_URL"
        echo "  git push azure main"
        ;;
esac
echo ""

# Wait for deployment to complete
echo -e "${BLUE}Step 8: Waiting for app to start...${NC}"
sleep 30

# Test the deployment
APP_URL="https://$APP_NAME.azurewebsites.net"
echo -e "${BLUE}Step 9: Testing deployment...${NC}"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/api/health")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Health check passed!${NC}"
else
    echo -e "${RED}⚠️  Health check returned: $HTTP_CODE${NC}"
    echo "The app may still be starting up. Check logs if issues persist."
fi
echo ""

# Display summary
echo "=========================================="
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}App Details:${NC}"
echo "  URL: $APP_URL"
echo "  Health Check: $APP_URL/api/health"
echo "  API Endpoint: $APP_URL/api/predict"
echo "  Resource Group: $RESOURCE_GROUP"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  View logs:"
echo "    az webapp log tail --name $APP_NAME --resource-group $RESOURCE_GROUP"
echo ""
echo "  Restart app:"
echo "    az webapp restart --name $APP_NAME --resource-group $RESOURCE_GROUP"
echo ""
echo "  Delete resources:"
echo "    az group delete --name $RESOURCE_GROUP --yes"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Visit $APP_URL to use the app"
echo "  2. Test the API endpoint"
echo "  3. Configure custom domain (optional)"
echo "  4. Set up monitoring (optional)"
echo ""
echo "=========================================="
