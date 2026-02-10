# 🚗 Car Price Prediction - Azure Production Ready

[![Python 3.13](https://img.shields.io/badge/Python-3.13-blue.svg)](https://www.python.org/downloads/)
[![Azure](https://img.shields.io/badge/Azure-Ready-0078D4.svg)](https://azure.microsoft.com/)
[![Flask](https://img.shields.io/badge/Flask-3.0.3-green.svg)](https://flask.palletsprojects.com/)
[![Accuracy](https://img.shields.io/badge/Accuracy-89.78%25-brightgreen.svg)]()

Production-ready ML application for predicting car prices, optimized for Azure App Service with Python 3.13.

## ✨ Key Features

- **89.78% Accuracy** - Gradient Boosting ML model
- **Beautiful UI** - Modern, responsive web interface
- **Azure Ready** - One-click deployment scripts
- **Python 3.13** - Latest Python version
- **RESTful API** - Production-grade endpoints
- **Real-time Predictions** - Instant results with confidence intervals

## 🚀 Quick Deploy to Azure

### Automated Deployment

**Linux/Mac:**
```bash
chmod +x deploy-to-azure.sh
./deploy-to-azure.sh
```

**Windows:**
```powershell
.\deploy-to-azure.ps1
```

That's it! The script handles everything automatically.

### What Gets Deployed
- ✅ Azure App Service (Python 3.13)
- ✅ ML model with 89.78% accuracy
- ✅ Beautiful web interface
- ✅ RESTful API endpoints
- ✅ HTTPS enabled
- ✅ Health monitoring

## 📊 Model Performance

| Metric | Value |
|--------|-------|
| Accuracy (R²) | **89.78%** |
| Mean Error | **$3,712** |
| Model | Gradient Boosting |
| Features | 13 total |

## 🔌 API Usage

### Predict Price
```bash
curl -X POST https://YOUR-APP.azurewebsites.net/api/predict \
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

### Health Check
```bash
curl https://YOUR-APP.azurewebsites.net/api/health
```

## 💻 Local Development

```bash
# Clone repo
git clone <your-repo>
cd car-price-predictor

# Setup virtual environment
python3.13 -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows

# Install dependencies
pip install -r requirements.txt

# Run locally
python app.py
```

Access at `http://localhost:8000`

## 📁 Files

| File | Purpose |
|------|---------|
| `app.py` | Flask application (Azure-optimized) |
| `requirements.txt` | Python 3.13 dependencies |
| `runtime.txt` | Python version for Azure |
| `deploy-to-azure.sh` | Linux/Mac deployment script |
| `deploy-to-azure.ps1` | Windows deployment script |
| `AZURE_DEPLOYMENT.md` | Detailed deployment guide |
| `static/index.html` | Web interface |

## 📚 Documentation

- **[Azure Deployment Guide](AZURE_DEPLOYMENT.md)** - Complete deployment instructions
- **[API Documentation](#-api-usage)** - Endpoint details
- **[Troubleshooting](#-troubleshooting)** - Common issues

## 💰 Azure Costs

| Tier | Cost/Month | Best For |
|------|------------|----------|
| Free F1 | $0 | Testing |
| Basic B1 | ~$13 | Small production |
| Standard S1 | ~$70 | Production |

## 🛠️ Troubleshooting

**App won't start?**
```bash
az webapp log tail --name YOUR-APP --resource-group car-price-predictor-rg
```

**Need to restart?**
```bash
az webapp restart --name YOUR-APP --resource-group car-price-predictor-rg
```

**Delete everything?**
```bash
az group delete --name car-price-predictor-rg --yes
```

## 🔒 Security

- HTTPS-only mode enabled
- Environment variables for secrets
- Input validation
- CORS configured
- Request size limits

## 📈 Monitoring

View logs in real-time:
```bash
az webapp log tail --name YOUR-APP --resource-group car-price-predictor-rg
```

Or use Azure Portal → Log Stream

## 🎯 Next Steps After Deployment

1. ✅ Test your app at `https://YOUR-APP.azurewebsites.net`
2. ✅ Try the API endpoint
3. ⚙️ Configure custom domain (optional)
4. 📊 Set up Application Insights (optional)
5. 🔄 Enable GitHub Actions for CI/CD (optional)

## 📄 License

MIT License - Open source and free to use

---

**Ready to deploy?** Run `./deploy-to-azure.sh` or see [AZURE_DEPLOYMENT.md](AZURE_DEPLOYMENT.md)

Built with Python 3.13 🐍 | Machine Learning 🤖 | Azure ☁️
