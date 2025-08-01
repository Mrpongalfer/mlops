# src/model_trainer.py
import joblib
from sklearn.ensemble import RandomForestClassifier
from src.config import config
def train_model(X_train, y_train):
    model = RandomForestClassifier(n_estimators=config['models']['random_forest']['n_estimators'], random_state=config['models']['random_forest']['random_state'], n_jobs=config['models']['random_forest']['n_jobs'])
    model.fit(X_train, y_train)
    joblib.dump(model, f"{config['paths']['models_dir']}/{config['paths']['model_filename']}")
    return model
if __name__ == '__main__':
    print("This script is meant to be called by the CI/CD pipeline.")
