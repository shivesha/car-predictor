# Azure Deployment Script for Car Price Prediction App (Windows)
# Run this in PowerShell

param(
    [string]$ResourceGroup = "car-price-predictor-rg",
    [string]$Location = "eastus",
    [string]$PlanName = "car-price-predictor-plan",
    [string]$Sku = "B1"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Car Price Predictor - Azure Deployment" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Generate unique app name
$AppName = "car-price-predictor-$(Get-Random -Minimum 1000 -Maximum 9999)"

Write-Host "Configuration:" -ForegroundColor Blue
Write-Host "  Resource Group: $ResourceGroup"
Write-Host "  Location: $Location"
Write-Host "  App Name: $AppName"
Write-Host "  Plan Name: $PlanName"
Write-Host "  SKU: $Sku"
Write-Host ""

# Check if Azure CLI is installed
try {
    $null = Get-Command az -ErrorAction Stop
    Write-Host "[OK] Azure CLI is installed" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Azure CLI is not installed!" -ForegroundColor Red
    Write-Host "Please install from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
}
Write-Host ""

# Login to Azure
Write-Host "Step 1: Logging in to Azure..." -ForegroundColor Blue
az login
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to login to Azure" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Successfully logged in" -ForegroundColor Green
Write-Host ""

# List subscriptions
Write-Host "Available subscriptions:" -ForegroundColor Blue
az account list --output table
Write-Host ""

# Create resource group
Write-Host "Step 2: Creating resource group..." -ForegroundColor Blue
az group create --name $ResourceGroup --location $Location --output table
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create resource group" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Resource group created" -ForegroundColor Green
Write-Host ""

# Create App Service plan
Write-Host "Step 3: Creating App Service plan..." -ForegroundColor Blue
az appservice plan create `
    --name $PlanName `
    --resource-group $ResourceGroup `
    --location $Location `
    --is-linux `
    --sku $Sku `
    --output table

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create App Service plan" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] App Service plan created" -ForegroundColor Green
Write-Host ""

# Create web app
Write-Host "Step 4: Creating Web App..." -ForegroundColor Blue
az webapp create `
    --name $AppName `
    --resource-group $ResourceGroup `
    --plan $PlanName `
    --runtime "PYTHON:3.13" `
    --output table

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create Web App" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Web App created" -ForegroundColor Green
Write-Host ""

# Generate secret key
$SecretKey = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})

# Configure app settings
Write-Host "Step 5: Configuring app settings..." -ForegroundColor Blue
az webapp config appsettings set `
    --name $AppName `
    --resource-group $ResourceGroup `
    --settings `
        SCM_DO_BUILD_DURING_DEPLOYMENT=true `
        SECRET_KEY=$SecretKey `
        WEBSITE_HTTPLOGGING_RETENTION_DAYS=7 `
    --output table

az webapp config set `
    --name $AppName `
    --resource-group $ResourceGroup `
    --startup-file "gunicorn --bind=0.0.0.0:8000 --timeout 600 --workers 2 app:app" `
    --output table

Write-Host "[OK] App settings configured" -ForegroundColor Green
Write-Host ""

# Enable HTTPS only
Write-Host "Step 6: Enabling HTTPS..." -ForegroundColor Blue
az webapp update `
    --name $AppName `
    --resource-group $ResourceGroup `
    --https-only true `
    --output table
Write-Host "[OK] HTTPS enabled" -ForegroundColor Green
Write-Host ""

# Deploy code
Write-Host "Step 7: Deploying code..." -ForegroundColor Blue
Write-Host "Creating deployment package..."

# Create ZIP file
$ZipPath = "deploy.zip"
if (Test-Path $ZipPath) {
    Remove-Item $ZipPath
}

# Compress files
Compress-Archive -Path * -DestinationPath $ZipPath -Force -Exclude @("*.git*", "*__pycache__*", "*.pkl", "deploy.zip")

Write-Host "Deploying to Azure..."
az webapp deployment source config-zip `
    --name $AppName `
    --resource-group $ResourceGroup `
    --src $ZipPath

Remove-Item $ZipPath
Write-Host "[OK] Code deployed" -ForegroundColor Green
Write-Host ""

# Wait for deployment
Write-Host "Step 8: Waiting for app to start..." -ForegroundColor Blue
Start-Sleep -Seconds 30

# Test deployment
$AppUrl = "https://$AppName.azurewebsites.net"
Write-Host "Step 9: Testing deployment..." -ForegroundColor Blue

try {
    $Response = Invoke-WebRequest -Uri "$AppUrl/api/health" -UseBasicParsing -TimeoutSec 10
    if ($Response.StatusCode -eq 200) {
        Write-Host "[OK] Health check passed!" -ForegroundColor Green
    }
} catch {
    Write-Host "[WARNING] Health check failed. App may still be starting up." -ForegroundColor Yellow
}
Write-Host ""

# Display summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "App Details:" -ForegroundColor Blue
Write-Host "  URL: $AppUrl"
Write-Host "  Health Check: $AppUrl/api/health"
Write-Host "  API Endpoint: $AppUrl/api/predict"
Write-Host "  Resource Group: $ResourceGroup"
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Blue
Write-Host "  View logs:"
Write-Host "    az webapp log tail --name $AppName --resource-group $ResourceGroup"
Write-Host ""
Write-Host "  Restart app:"
Write-Host "    az webapp restart --name $AppName --resource-group $ResourceGroup"
Write-Host ""
Write-Host "  Delete resources:"
Write-Host "    az group delete --name $ResourceGroup --yes"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Blue
Write-Host "  1. Visit $AppUrl to use the app"
Write-Host "  2. Test the API endpoint"
Write-Host "  3. Configure custom domain (optional)"
Write-Host "  4. Set up monitoring (optional)"
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
