# src/model_evaluator.py
import json
import joblib
import pandas as pd
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
from sklearn.model_selection import train_test_split
from src.config import config
def evaluate_model(model_path: str, preprocessor_path: str, data_path: str):
    df = pd.read_csv(data_path)
    X = df.drop('target', axis=1)
    y = df['target']
    preprocessor = joblib.load(preprocessor_path)
    X_processed = preprocessor.transform(X)
    X_train, X_test, y_train, y_test = train_test_split(X_processed, y, test_size=config['data']['test_size'], random_state=config['data']['random_state'])
    model = joblib.load(model_path)
    y_pred = model.predict(X_test)
    metrics = {
        "accuracy": accuracy_score(y_test, y_pred),
        "precision": precision_score(y_test, y_pred, average='weighted', zero_division=0),
        "recall": recall_score(y_test, y_pred, average='weighted', zero_division=0),
        "f1_score": f1_score(y_test, y_pred, average='weighted', zero_division=0),
    }
    with open(f"{config['paths']['reports_dir']}/{config['paths']['metrics_filename']}", 'w') as f:
        json.dump(metrics, f, indent=4)
if __name__ == '__main__':
    print("This script is meant to be called by the CI/CD pipeline.")
