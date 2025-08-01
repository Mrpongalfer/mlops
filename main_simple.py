# main.py
from fastapi import FastAPI, Request
from prometheus_client import Histogram, Counter, generate_latest
import time
from pydantic import BaseModel
from src.config import config
import joblib

app = FastAPI(title="AI Model Serving API", description="A FastAPI service for model predictions.")

request_latency = Histogram("api_request_latency_seconds", "API Request Latency", ["endpoint"])
request_counter = Counter("api_requests_total", "Total API Requests", ["endpoint", "method", "status_code"])
prediction_errors = Counter("prediction_errors_total", "Prediction Errors Total")

class PredictionInput(BaseModel):
    data: list

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    request_latency.labels(request.url.path).observe(process_time)
    request_counter.labels(request.url.path, request.method, response.status_code).inc()
    return response

@app.get(f"{config['api']['version']}/health")
async def health_check():
    return {"status": "ok", "message": "API is running successfully."}

@app.get(f"{config['api']['version']}/ready")
async def readiness_check():
    return {"status": "ready", "message": "API is ready to serve requests."}

# Replace mock prediction logic with actual model inference
@app.post(f"{config['api']['version']}/predict")
async def predict(input_data: PredictionInput):
    try:
        # Load the model and preprocessor
        preprocessor = joblib.load(config['paths']['preprocessor_filename'])
        model = joblib.load(config['paths']['model_filename'])

        # Preprocess the input data
        processed_data = preprocessor.transform(input_data.data)

        # Make predictions
        prediction = model.predict(processed_data).tolist()
        return {"prediction": prediction}
    except Exception as e:
        prediction_errors.inc()
        return {"error": str(e)}

@app.get("/metrics")
async def metrics():
    return generate_latest().decode("utf-8")

@app.get("/")
async def root():
    return {"message": "Welcome to the Omnitide AI Suite API"}
