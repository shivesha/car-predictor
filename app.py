"""
Perfect Car Price Prediction - Azure Production Ready
====================================================
Flask API Backend for Python 3.13 with Azure App Service deployment
"""

from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.metrics import mean_absolute_error, r2_score
import pickle
import os
import logging
from datetime import datetime
from pathlib import Path

# Configure logging for Azure
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Enable CORS for Azure
CORS(app, resources={
    r"/api/*": {
        "origins": "*",
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type"]
    }
})


class CarPriceMLModel:
    """Production ML Model for Car Price Prediction - Python 3.13 Compatible"""
    
    def __init__(self):
        self.model = None
        self.scaler = StandardScaler()
        self.label_encoders = {}
        self.feature_names = None
        self.metrics = {}
        self.is_trained = False
        self.model_version = "1.0.0"
        self.last_trained = None
    
    def create_training_data(self, n_samples: int = 2000) -> pd.DataFrame:
        """Generate realistic synthetic training data"""
        np.random.seed(42)
        
        brands = ['Toyota', 'Honda', 'BMW', 'Mercedes', 'Audi', 'Ford', 
                 'Chevrolet', 'Nissan', 'Volkswagen', 'Hyundai']
        fuel_types = ['Petrol', 'Diesel', 'Electric', 'Hybrid']
        transmissions = ['Manual', 'Automatic']
        body_types = ['Sedan', 'SUV', 'Hatchback', 'Coupe', 'Wagon', 'Convertible']
        
        data = {
            'brand': np.random.choice(brands, n_samples),
            'year': np.random.randint(2005, 2025, n_samples),
            'mileage': np.random.exponential(45000, n_samples),
            'fuel_type': np.random.choice(fuel_types, n_samples),
            'transmission': np.random.choice(transmissions, n_samples),
            'engine_size': np.random.uniform(1.0, 6.0, n_samples),
            'horsepower': np.random.randint(80, 500, n_samples),
            'body_type': np.random.choice(body_types, n_samples),
            'doors': np.random.choice([2, 4, 5], n_samples),
            'previous_owners': np.random.randint(0, 5, n_samples),
        }
        
        df = pd.DataFrame(data)
        
        # Create realistic price
        base_price = 15000
        brand_prices = {
            'BMW': 15000, 'Mercedes': 18000, 'Audi': 14000,
            'Toyota': 2000, 'Honda': 1500, 'Ford': 0,
            'Chevrolet': -1000, 'Nissan': 500, 'Volkswagen': 1200, 
            'Hyundai': 800
        }
        body_prices = {
            'SUV': 5000, 'Sedan': 2000, 'Coupe': 3000,
            'Hatchback': 0, 'Wagon': 1000, 'Convertible': 4000
        }
        fuel_prices = {
            'Electric': 8000, 'Hybrid': 4000,
            'Diesel': 2000, 'Petrol': 0
        }
        
        df['price'] = (
            base_price +
            (df['year'] - 2010) * 2000 +
            df['horsepower'] * 50 +
            df['engine_size'] * 3000 +
            df['brand'].map(brand_prices).fillna(0) +
            df['body_type'].map(body_prices).fillna(0) +
            df['fuel_type'].map(fuel_prices).fillna(0) +
            (df['transmission'] == 'Automatic').astype(int) * 2000 -
            df['mileage'] * 0.1 -
            df['previous_owners'] * 1500 +
            np.random.normal(0, 3000, n_samples)
        )
        
        df['price'] = df['price'].clip(lower=5000)
        return df
    
    def engineer_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Create engineered features"""
        df = df.copy()
        current_year = datetime.now().year
        df['car_age'] = current_year - df['year']
        df['mileage_per_year'] = df['mileage'] / (df['car_age'] + 1)
        df['power_to_weight'] = df['horsepower'] / df['engine_size']
        return df
    
    def preprocess(self, df: pd.DataFrame, is_training: bool = True) -> pd.DataFrame:
        """Preprocess features"""
        df = self.engineer_features(df)
        
        categorical_cols = ['brand', 'fuel_type', 'transmission', 'body_type']
        
        for col in categorical_cols:
            if col in df.columns:
                if is_training:
                    self.label_encoders[col] = LabelEncoder()
                    df[col] = self.label_encoders[col].fit_transform(df[col])
                else:
                    known_categories = set(self.label_encoders[col].classes_)
                    df[col] = df[col].apply(
                        lambda x: x if x in known_categories else self.label_encoders[col].classes_[0]
                    )
                    df[col] = self.label_encoders[col].transform(df[col])
        
        return df
    
    def train(self) -> 'CarPriceMLModel':
        """Train the model"""
        try:
            logger.info("Starting model training...")
            
            df = self.create_training_data(2000)
            logger.info(f"Generated {len(df)} training samples")
            
            df_processed = self.preprocess(df, is_training=True)
            
            X = df_processed.drop(columns=['price'])
            y = df_processed['price']
            self.feature_names = X.columns.tolist()
            
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=0.2, random_state=42
            )
            
            X_train_scaled = self.scaler.fit_transform(X_train)
            X_test_scaled = self.scaler.transform(X_test)
            
            self.model = GradientBoostingRegressor(
                n_estimators=200,
                learning_rate=0.1,
                max_depth=5,
                random_state=42
            )
            self.model.fit(X_train_scaled, y_train)
            
            y_pred = self.model.predict(X_test_scaled)
            mae = mean_absolute_error(y_test, y_pred)
            r2 = r2_score(y_test, y_pred)
            
            self.metrics = {
                'mae': float(mae),
                'r2': float(r2),
                'accuracy': float(r2 * 100)
            }
            
            self.is_trained = True
            self.last_trained = datetime.now().isoformat()
            
            logger.info(f"Model trained - MAE: ${mae:,.2f}, R²: {r2:.4f}")
            
            return self
            
        except Exception as e:
            logger.error(f"Error training model: {str(e)}")
            raise
    
    def predict(self, car_data: dict) -> dict:
        """Make prediction"""
        if not self.is_trained:
            raise ValueError("Model not trained")
        
        try:
            df = pd.DataFrame([car_data])
            df_processed = self.preprocess(df, is_training=False)
            df_scaled = self.scaler.transform(df_processed)
            price = float(self.model.predict(df_scaled)[0])
            
            mae = self.metrics['mae']
            confidence = {
                'lower': float(max(price - 1.96 * mae, 0)),
                'upper': float(price + 1.96 * mae)
            }
            
            current_year = datetime.now().year
            features = {
                'car_age': int(current_year - car_data['year']),
                'mileage_per_year': float(car_data['mileage'] / (current_year - car_data['year'] + 1)),
                'power_to_weight': float(car_data['horsepower'] / car_data['engine_size'])
            }
            
            return {
                'price': price,
                'confidence': confidence,
                'features': features,
                'accuracy': self.metrics['accuracy'],
                'mae': self.metrics['mae']
            }
            
        except Exception as e:
            logger.error(f"Error making prediction: {str(e)}")
            raise
    
    def save(self, path: str = 'car_price_model.pkl') -> None:
        """Save model"""
        try:
            model_data = {
                'model': self.model,
                'scaler': self.scaler,
                'label_encoders': self.label_encoders,
                'feature_names': self.feature_names,
                'metrics': self.metrics,
                'is_trained': self.is_trained,
                'model_version': self.model_version,
                'last_trained': self.last_trained
            }
            
            Path(path).parent.mkdir(parents=True, exist_ok=True)
            
            with open(path, 'wb') as f:
                pickle.dump(model_data, f)
            
            logger.info(f"Model saved to {path}")
            
        except Exception as e:
            logger.error(f"Error saving model: {str(e)}")
            raise
    
    def load(self, path: str = 'car_price_model.pkl') -> None:
        """Load model"""
        try:
            with open(path, 'rb') as f:
                model_data = pickle.load(f)
            
            self.model = model_data['model']
            self.scaler = model_data['scaler']
            self.label_encoders = model_data['label_encoders']
            self.feature_names = model_data['feature_names']
            self.metrics = model_data['metrics']
            self.is_trained = model_data['is_trained']
            self.model_version = model_data.get('model_version', '1.0.0')
            self.last_trained = model_data.get('last_trained', 'Unknown')
            
            logger.info(f"Model loaded from {path}")
            
        except Exception as e:
            logger.error(f"Error loading model: {str(e)}")
            raise


# Initialize model
ml_model = CarPriceMLModel()

# Azure-compatible model path
if os.environ.get('WEBSITE_SITE_NAME'):
    model_path = '/home/car_price_model.pkl'
else:
    model_path = 'car_price_model.pkl'

# Load or train model
if os.path.exists(model_path):
    try:
        ml_model.load(model_path)
        logger.info("Loaded existing model")
    except Exception as e:
        logger.warning(f"Failed to load model: {e}. Training new model...")
        ml_model.train()
        ml_model.save(model_path)
else:
    logger.info("Training new model...")
    ml_model.train()
    ml_model.save(model_path)


@app.route('/')
def index():
    """Serve main page"""
    try:
        static_file = os.path.join(os.path.dirname(__file__), 'static', 'index.html')
        if os.path.exists(static_file):
            return send_from_directory('static', 'index.html')
        else:
            return jsonify({
                'status': 'online',
                'message': 'Car Price Prediction API',
                'version': ml_model.model_version,
                'endpoints': {
                    'predict': '/api/predict (POST)',
                    'model_info': '/api/model-info (GET)',
                    'health': '/api/health (GET)'
                }
            })
    except Exception as e:
        logger.error(f"Error serving index: {str(e)}")
        return jsonify({'error': 'Server error'}), 500


@app.route('/api/predict', methods=['POST', 'OPTIONS'])
def predict_price():
    """Predict car price"""
    if request.method == 'OPTIONS':
        return '', 204
    
    try:
        data = request.json
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        required_fields = [
            'brand', 'year', 'mileage', 'fuelType', 
            'transmission', 'engineSize', 'horsepower',
            'bodyType', 'doors', 'previousOwners'
        ]
        
        missing_fields = [field for field in required_fields if field not in data]
        if missing_fields:
            return jsonify({
                'error': f'Missing fields: {", ".join(missing_fields)}'
            }), 400
        
        car_data = {
            'brand': str(data['brand']),
            'year': int(data['year']),
            'mileage': float(data['mileage']),
            'fuel_type': str(data['fuelType']),
            'transmission': str(data['transmission']),
            'engine_size': float(data['engineSize']),
            'horsepower': int(data['horsepower']),
            'body_type': str(data['bodyType']),
            'doors': int(data['doors']),
            'previous_owners': int(data['previousOwners'])
        }
        
        prediction = ml_model.predict(car_data)
        
        logger.info(f"Prediction: ${prediction['price']:,.2f}")
        
        return jsonify({
            'success': True,
            'prediction': prediction,
            'timestamp': datetime.now().isoformat()
        })
    
    except ValueError as e:
        logger.error(f"Validation error: {str(e)}")
        return jsonify({
            'success': False,
            'error': f'Invalid input: {str(e)}'
        }), 400
    
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500


@app.route('/api/model-info', methods=['GET'])
def model_info():
    """Get model information"""
    try:
        return jsonify({
            'is_trained': ml_model.is_trained,
            'metrics': ml_model.metrics,
            'feature_names': ml_model.feature_names,
            'model_version': ml_model.model_version,
            'last_trained': ml_model.last_trained
        })
    except Exception as e:
        logger.error(f"Error getting model info: {str(e)}")
        return jsonify({'error': 'Server error'}), 500


@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check for Azure"""
    try:
        return jsonify({
            'status': 'healthy',
            'model_loaded': ml_model.is_trained,
            'timestamp': datetime.now().isoformat(),
            'version': ml_model.model_version
        })
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 500


@app.errorhandler(404)
def not_found(e):
    return jsonify({'error': 'Resource not found'}), 404


@app.errorhandler(500)
def internal_error(e):
    logger.error(f"Internal error: {str(e)}")
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    
    logger.info("="*60)
    logger.info("🚗 CAR PRICE PREDICTION API SERVER")
    logger.info("="*60)
    logger.info(f"Model Status: {'Trained' if ml_model.is_trained else 'Not Trained'}")
    logger.info(f"Accuracy: {ml_model.metrics.get('accuracy', 0):.2f}%")
    logger.info(f"MAE: ${ml_model.metrics.get('mae', 0):,.2f}")
    logger.info(f"Port: {port}")
    logger.info("="*60)
    
    app.run(
        host='0.0.0.0',
        port=port,
        debug=False,
        threaded=True
    )
