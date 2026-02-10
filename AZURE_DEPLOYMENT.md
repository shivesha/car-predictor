# 🚀 Azure Deployment Guide - Car Price Prediction App

## Complete step-by-step guide for deploying to Azure App Service with Python 3.13

---

## 📋 Prerequisites

1. **Azure Account** - [Sign up for free](https://azure.microsoft.com/free/)
2. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
3. **Git** - [Install Git](https://git-scm.com/downloads)
4. **Python 3.13** - [Install Python](https://www.python.org/downloads/)

---

## 🎯 Method 1: Deploy via Azure Portal (Easiest)

### Step 1: Prepare Your Code

Your project structure should look like this:
```
car-price-predictor/
├── app.py                    # Main Flask application
├── requirements.txt          # Python dependencies
├── runtime.txt              # Python version (3.13)
├── startup.txt              # Gunicorn startup command
├── .deployment              # Azure deployment config
├── .gitignore              # Git ignore file
├── static/
│   └── index.html          # Web interface
└── AZURE_DEPLOYMENT.md     # This file
```

### Step 2: Create Azure App Service

1. Go to [Azure Portal](https://portal.azure.com)
2. Click **"Create a resource"**
3. Search for **"Web App"** and click **Create**

4. **Configure your web app:**
   - **Subscription**: Select your subscription
   - **Resource Group**: Create new (e.g., "car-price-predictor-rg")
   - **Name**: Choose unique name (e.g., "car-price-predictor-app")
   - **Publish**: **Code**
   - **Runtime stack**: **Python 3.13**
   - **Operating System**: **Linux**
   - **Region**: Choose closest region (e.g., "East US")
   - **Pricing Plan**: Select appropriate plan
     - **Free F1** - For testing (limited resources)
     - **Basic B1** - For production ($13/month)
     - **Standard S1** - For better performance ($70/month)

5. Click **"Review + Create"** then **"Create"**

### Step 3: Deploy Your Code

#### Option A: Deploy from GitHub (Recommended)

1. Push your code to GitHub:
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/car-price-predictor.git
git push -u origin main
```

2. In Azure Portal, go to your Web App
3. Click **"Deployment Center"** in left menu
4. Select **GitHub** as source
5. Authorize and select your repository
6. Azure will automatically deploy your app

#### Option B: Deploy from Local Git

1. In Azure Portal, go to your Web App
2. Click **"Deployment Center"**
3. Select **"Local Git"**
4. Click **"Save"**
5. Copy the Git URL provided

6. Deploy from your local machine:
```bash
git init
git add .
git commit -m "Initial commit"
git remote add azure <AZURE_GIT_URL>
git push azure main
```

#### Option C: Deploy via ZIP

1. Create a ZIP file of your project:
```bash
zip -r car-price-predictor.zip . -x "*.git*" -x "*__pycache__*" -x "*.pkl"
```

2. In Azure Portal, go to your Web App
3. Click **"Advanced Tools"** → **"Go"** (Kudu)
4. Go to **"Tools"** → **"Zip Push Deploy"**
5. Drag and drop your ZIP file

### Step 4: Configure App Settings

1. In Azure Portal, go to your Web App
2. Click **"Configuration"** in left menu
3. Add these **Application Settings**:

| Name | Value | Description |
|------|-------|-------------|
| `SCM_DO_BUILD_DURING_DEPLOYMENT` | `true` | Build during deployment |
| `WEBSITE_HTTPLOGGING_RETENTION_DAYS` | `7` | Keep logs for 7 days |
| `SECRET_KEY` | `your-secret-key-here` | Flask secret key |

4. Under **"General settings"**:
   - **Startup Command**: `gunicorn --bind=0.0.0.0:8000 --timeout 600 --workers 2 app:app`

5. Click **"Save"**

### Step 5: Verify Deployment

1. Go to your app URL: `https://YOUR-APP-NAME.azurewebsites.net`
2. Check health endpoint: `https://YOUR-APP-NAME.azurewebsites.net/api/health`
3. Test the interface and make a prediction

---

## 🎯 Method 2: Deploy via Azure CLI (Advanced)

### Step 1: Install and Login

```bash
# Install Azure CLI
# Windows: Download from https://aka.ms/installazurecliwindows
# Mac: brew install azure-cli
# Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### Step 2: Create Resources

```bash
# Set variables
RESOURCE_GROUP="car-price-predictor-rg"
LOCATION="eastus"
APP_NAME="car-price-predictor-app"
PLAN_NAME="car-price-predictor-plan"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create App Service plan
az appservice plan create \
    --name $PLAN_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --is-linux \
    --sku B1

# Create web app
az webapp create \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --plan $PLAN_NAME \
    --runtime "PYTHON:3.13"
```

### Step 3: Configure App

```bash
# Set startup command
az webapp config set \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --startup-file "gunicorn --bind=0.0.0.0:8000 --timeout 600 --workers 2 app:app"

# Set app settings
az webapp config appsettings set \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --settings \
        SCM_DO_BUILD_DURING_DEPLOYMENT=true \
        SECRET_KEY="your-secret-key-here"
```

### Step 4: Deploy Code

```bash
# Deploy from local git
az webapp deployment source config-local-git \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP

# Get deployment credentials
az webapp deployment list-publishing-credentials \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "{username:publishingUserName, password:publishingPassword}"

# Add Azure remote and push
git remote add azure https://$APP_NAME.scm.azurewebsites.net/$APP_NAME.git
git push azure main
```

---

## 🎯 Method 3: Deploy via VS Code (Developer-Friendly)

### Step 1: Install Extensions

1. Install **Azure Tools** extension in VS Code
2. Install **Python** extension in VS Code

### Step 2: Sign in to Azure

1. Click Azure icon in VS Code sidebar
2. Sign in to your Azure account

### Step 3: Deploy

1. Right-click your project folder
2. Select **"Deploy to Web App"**
3. Follow the prompts:
   - Create new web app or select existing
   - Choose subscription
   - Enter app name
   - Select Python 3.13 runtime
   - Select region

4. VS Code will automatically deploy your app

---

## 📊 Monitoring & Troubleshooting

### View Logs

#### In Azure Portal:
1. Go to your Web App
2. Click **"Log stream"** in left menu
3. View real-time logs

#### Via Azure CLI:
```bash
# Stream logs
az webapp log tail \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP

# Download logs
az webapp log download \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --log-file logs.zip
```

### Common Issues & Solutions

#### Issue 1: App doesn't start
**Solution**: Check startup command
```bash
az webapp config show \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "linuxFxVersion"
```

#### Issue 2: Dependencies not installing
**Solution**: Verify requirements.txt
```bash
# SSH into your app
az webapp ssh --name $APP_NAME --resource-group $RESOURCE_GROUP

# Check pip freeze
pip freeze
```

#### Issue 3: Out of memory
**Solution**: Increase workers in gunicorn or upgrade plan
```bash
# In startup command, reduce workers:
gunicorn --bind=0.0.0.0:8000 --timeout 600 --workers 1 app:app
```

#### Issue 4: Model file not persisting
**Solution**: Models are saved in `/home` directory which persists across restarts

---

## 🔒 Security Best Practices

### 1. Use Environment Variables for Secrets

In Azure Portal → Configuration → Application settings:
```
SECRET_KEY=<generate-strong-key>
```

### 2. Enable HTTPS Only

```bash
az webapp update \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --https-only true
```

### 3. Configure CORS Properly

In `app.py`, update CORS to allow only your domains:
```python
CORS(app, resources={
    r"/api/*": {
        "origins": ["https://yourdomain.com"],
        "methods": ["GET", "POST"],
        "allow_headers": ["Content-Type"]
    }
})
```

### 4. Enable Application Insights

```bash
az monitor app-insights component create \
    --app $APP_NAME \
    --location $LOCATION \
    --resource-group $RESOURCE_GROUP
```

---

## 📈 Scaling Options

### Vertical Scaling (Bigger Machine)
```bash
# Upgrade to Standard S2
az appservice plan update \
    --name $PLAN_NAME \
    --resource-group $RESOURCE_GROUP \
    --sku S2
```

### Horizontal Scaling (More Instances)
```bash
# Scale to 3 instances
az appservice plan update \
    --name $PLAN_NAME \
    --resource-group $RESOURCE_GROUP \
    --number-of-workers 3
```

### Auto-scaling
1. Go to Azure Portal
2. Navigate to your App Service Plan
3. Click **"Scale out (App Service plan)"**
4. Configure auto-scale rules based on CPU/Memory

---

## 💰 Cost Optimization

### Pricing Tiers Comparison

| Tier | Price/Month | RAM | Storage | Good For |
|------|-------------|-----|---------|----------|
| Free F1 | $0 | 1 GB | 1 GB | Development/Testing |
| Basic B1 | ~$13 | 1.75 GB | 10 GB | Small production apps |
| Standard S1 | ~$70 | 1.75 GB | 50 GB | Production apps |
| Premium P1v2 | ~$90 | 3.5 GB | 250 GB | High-performance apps |

### Cost-Saving Tips

1. **Use Free tier for development**
2. **Stop app when not in use**:
```bash
az webapp stop --name $APP_NAME --resource-group $RESOURCE_GROUP
```

3. **Use deployment slots for testing** (Standard tier+)
4. **Monitor usage** in Azure Portal → Cost Management

---

## 🧪 Testing Your Deployment

### Health Check
```bash
curl https://YOUR-APP-NAME.azurewebsites.net/api/health
```

### Make a Prediction
```bash
curl -X POST https://YOUR-APP-NAME.azurewebsites.net/api/predict \
  -H "Content-Type: application/json" \
  -d '{
    "brand": "BMW",
    "year": 2020,
    "mileage": 25000,
    "fuelType": "Petrol",
    "transmission": "Automatic",
    "engineSize": 3.0,
    "horsepower": 300,
    "bodyType": "Sedan",
    "doors": 4,
    "previousOwners": 1
  }'
```

### Load Testing
```bash
# Install Apache Bench
# Then run 100 requests with 10 concurrent
ab -n 100 -c 10 https://YOUR-APP-NAME.azurewebsites.net/api/health
```

---

## 🔄 Continuous Deployment

### GitHub Actions

Create `.github/workflows/azure-deploy.yml`:

```yaml
name: Deploy to Azure

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Python 3.13
      uses: actions/setup-python@v2
      with:
        python-version: 3.13
    
    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: 'YOUR-APP-NAME'
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
```

Get publish profile from Azure Portal → Download publish profile

---

## 📞 Support & Resources

- **Azure Documentation**: https://docs.microsoft.com/azure/app-service/
- **Python on Azure**: https://docs.microsoft.com/azure/app-service/quickstart-python
- **Azure Status**: https://status.azure.com/
- **Pricing Calculator**: https://azure.microsoft.com/pricing/calculator/

---

## ✅ Deployment Checklist

- [ ] Code pushed to Git repository
- [ ] requirements.txt includes all dependencies
- [ ] runtime.txt specifies Python 3.13
- [ ] startup.txt has correct gunicorn command
- [ ] App Service created in Azure Portal
- [ ] Deployment configured (GitHub/Local Git/ZIP)
- [ ] Application settings configured
- [ ] HTTPS enabled
- [ ] Health endpoint returns 200 OK
- [ ] Web interface loads correctly
- [ ] API predictions working
- [ ] Logs monitoring configured
- [ ] Backup strategy in place (if needed)

---

**🎉 Congratulations! Your Car Price Prediction App is now live on Azure!**

Access your app at: `https://YOUR-APP-NAME.azurewebsites.net`
