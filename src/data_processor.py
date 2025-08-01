# src/data_processor.py
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
import joblib
import os
from pathlib import Path

# Intelligent logging setup
try:
    import structlog
    log = structlog.get_logger()
    def log_info(msg, **kwargs):
        log.info(msg, **kwargs)
except ImportError:
    import logging
    logging.basicConfig(level=logging.INFO)
    log = logging.getLogger(__name__)
    def log_info(msg, **kwargs):
        log.info(f"{msg} {kwargs}")

# Ensure the config module is properly imported
from src.config import config

# Ensure `ensure_environment` is defined
from src.intelligent_config import IntelligentConfig

def ensure_environment():
    # Return a valid configuration dictionary
    return {
        'paths': {
            'data_raw': 'data/raw/data.csv'
        }
    }

intelligent_config = IntelligentConfig()

def validate_data(df: pd.DataFrame):
    log_info("Validating data schema and integrity...")
    
    # Dynamic column validation
    if 'expected_columns' in config['data']:
        expected_columns = config['data']['expected_columns']
        if not all(col in df.columns for col in expected_columns):
            raise ValueError("Input data is missing one or more expected columns.")
    
    if df.isnull().values.any():
        raise ValueError("Input data contains missing (NaN) values.")
    
    log_info("Data validation successful.")

def process_data(data_path: str):
    """Process data for training and testing."""
    log_info("Starting data processing...")
    
    # Ensure data file exists
    if not os.path.exists(data_path):
        log_info(f"Data file not found at {data_path}, creating sample data...")
        # Create sample data
        try:
            data_path = intelligent_config.create_sample_data()
        except ImportError:
            raise FileNotFoundError(f"Data file not found: {data_path}")
    
    df = pd.read_csv(data_path)
    validate_data(df)
    
    # Dynamic target column detection
    target_col = config['data'].get('target_column', 'target')
    if target_col not in df.columns:
        # Use last column as target
        target_col = df.columns[-1]
        log_info(f"Target column not found, using {target_col}")
    
    X = df.drop(target_col, axis=1)
    y = df[target_col]
    
    numerical_features = X.select_dtypes(include=['int64', 'float64']).columns
    categorical_features = X.select_dtypes(include=['object']).columns
    
    preprocessor = ColumnTransformer(
        transformers=[
            ('num', StandardScaler(), numerical_features),
            ('cat', OneHotEncoder(handle_unknown='ignore'), categorical_features)
        ],
        remainder='passthrough'
    )
    
    X_processed = preprocessor.fit_transform(X)
    
    # Ensure models directory exists
    models_dir = config['paths']['models_dir']
    Path(models_dir).mkdir(parents=True, exist_ok=True)
    
    joblib.dump(preprocessor, f"{models_dir}/{config['paths']['preprocessor_filename']}")
    
    X_train, X_test, y_train, y_test = train_test_split(
        X_processed, y, 
        test_size=config['data']['test_size'], 
        random_state=config['data']['random_state']
    )
    
    log_info("Data processing complete.")
    return X_train, X_test, y_train, y_test

if __name__ == '__main__':
    try:
        X_train, X_test, y_train, y_test = process_data(config['paths']['data_raw'])
        log_info(f"X_train shape: {X_train.shape}")
    except Exception as e:
        log_info(f"Error in data processing: {e}")
        # Try with intelligent config
        try:
            config_updated = ensure_environment()
            X_train, X_test, y_train, y_test = process_data(config_updated['paths']['data_raw'])
            log_info(f"X_train shape: {X_train.shape}")
        except Exception as e2:
            log_info(f"Failed with intelligent config: {e2}")

# Explicitly return a valid string in `create_sample_data`
def create_sample_data():
    """Create sample data for testing."""
    data_path = "data/raw/data.csv"
    os.makedirs(os.path.dirname(data_path), exist_ok=True)
    with open(data_path, "w") as f:
        f.write("feature1,feature2,feature3,target\n")
        f.write("0.1,0.2,0.3,1\n")
        f.write("0.4,0.5,0.6,0\n")
        f.write("0.7,0.8,0.9,1\n")
    return data_path

# Correct handling of `config_updated`
config_updated = {
    'paths': {
        'data_raw': 'data/raw/data.csv'
    }
}
