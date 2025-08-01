# main.py
import os
import sys
from pathlib import Path
import joblib
import structlog
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse, PlainTextResponse
from prometheus_client import Histogram, Counter, generate_latest
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
from src.intelligent_config import IntelligentConfig
import pandas as pd
import time

# Initialize intelligent configuration
intelligent_config = IntelligentConfig()

# Auto-heal project on startup
log = structlog.get_logger()
log.info("🚀 Starting Omnitide AI Suite - Initializing...")
log.info("🔧 Performing startup self-healing...")
healing_actions = intelligent_config.heal_project()
for action in healing_actions:
    log.info(action, source="heal_project")

# Get dynamic configuration
config = intelligent_config.get_dynamic_config()

request_latency = Histogram("api_request_latency_seconds", "API Request Latency", ["endpoint"])
request_counter = Counter("api_requests_total", "Total API Requests", ["endpoint", "method", "status_code"])
prediction_errors = Counter("prediction_errors_total", "Prediction Errors Total")

class PredictionInput(BaseModel):
    data: List[List[float]]

class AgentTask(BaseModel):
    task_name: str
    parameters: Optional[Dict[str, Any]] = None

class HealthResponse(BaseModel):
    status: str
    message: str
    environment: Dict[str, Any]
    healing_actions: List[str]

# Try to load models with fallback
MODEL = None
PREPROCESSOR = None
MODEL_LOADED = False

try:
    models_dir = Path(config['paths']['models_dir'])
    model_path = models_dir / config['paths'].get('model_filename', 'model.joblib')
    preprocessor_path = models_dir / config['paths'].get('preprocessor_filename', 'preprocessor.joblib')
    
    if model_path.exists():
        MODEL = joblib.load(model_path)
        log.info("✅ Model loaded successfully", path=str(model_path))
    else:
        log.warning("Model file not found", path=str(model_path))
        
    if preprocessor_path.exists():
        PREPROCESSOR = joblib.load(preprocessor_path)
        log.info("✅ Preprocessor loaded successfully", path=str(preprocessor_path))
    else:
        log.warning("Preprocessor file not found", path=str(preprocessor_path))

    if MODEL is not None and PREPROCESSOR is not None:
        MODEL_LOADED = True
        log.info("🤖 Model and preprocessor are ready for predictions.")
        
except Exception as e:
    log.warning("Could not load models on startup", error=str(e))

app = FastAPI(
    title="Omnitide AI Suite API", 
    description="Dynamic, self-healing FastAPI service with intelligent configuration",
    version=config['project']['version']
)
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    request_latency.labels(request.url.path).observe(process_time)
    request_counter.labels(request.url.path, request.method, response.status_code).inc()
    return response

@app.get("/", response_model=Dict[str, Any])
async def root():
    """Provide basic information about the API."""
    return {
        "message": "Welcome to the Omnitide AI Suite API",
        "version": config['project']['version'],
        "intelligent_mode": True,
        "model_loaded": MODEL_LOADED
    }

@app.get(f"{config['api']['version']}/health", response_model=HealthResponse)
async def health_check():
    """Return a detailed health check of the system."""
    return {
        "status": "ok",
        "message": "API is running and configured.",
        "environment": intelligent_config.detect_environment(),
        "healing_actions": healing_actions
    }

@app.get(f"{config['api']['version']}/ready")
async def readiness_check():
    """Check if the API is ready to serve requests (e.g., model loaded)."""
    if not MODEL_LOADED:
        raise HTTPException(
            status_code=503,
            detail="Service Unavailable: Model not loaded."
        )
    return {"status": "ready", "message": "API is ready to serve predictions."}

@app.post(f"{config['api']['version']}/predict")
async def predict(input_data: PredictionInput):
    """Make predictions using the loaded model."""
    if not MODEL_LOADED:
        log.error("Prediction attempted but model not loaded.")
        raise HTTPException(
            status_code=503,
            detail="Model is not available for predictions."
        )
    
    try:
        # Preprocess the input data
        processed_data = PREPROCESSOR.transform(input_data.data)
        # Make predictions
        predictions = MODEL.predict(processed_data).tolist()
        
        log.info("Prediction successful", num_predictions=len(predictions))
        return {"prediction": predictions}
        
    except Exception as e:
        prediction_errors.inc()
        log.error("Prediction failed", error=str(e), input_data=input_data.data)
        raise HTTPException(status_code=500, detail=f"Prediction error: {e}")

@app.post(f"{config['api']['version']}/agent/execute")
async def execute_agent_task(task: AgentTask):
    """Execute an intelligent agent task."""
    log.info("Executing agent task", task_name=task.task_name)
    result = intelligent_config.orchestrate_agent_task(
        task.task_name, task.parameters
    )
    if not result.get("success"):
        raise HTTPException(status_code=400, detail=result)
    return result

@app.post(f"{config['api']['version']}/heal")
async def trigger_healing():
    """Trigger a manual self-healing process."""
    log.info("Manual healing process triggered via API.")
    actions = intelligent_config.heal_project()
    return {"actions": actions}

@app.get(f"{config['api']['version']}/config")
async def get_current_config():
    """Return the current dynamic configuration."""
    return config

@app.get("/metrics", response_class=PlainTextResponse)
async def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest().decode("utf-8")

# Error handlers
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler to ensure consistent error responses."""
    log.error("Unhandled exception", error=str(exc), path=request.url.path)
    return JSONResponse(
        status_code=500,
        content={"detail": f"An internal server error occurred: {exc}"},
    )

if __name__ == "__main__":
    import uvicorn
        
    # Use dynamic port from config
    port = config.get('api', {}).get('port', 8000)
    host = config.get('api', {}).get('host', '0.0.0.0')
    
    log.info(f"🚀 Starting Omnitide AI Suite on {host}:{port}")
    uvicorn.run(app, host=host, port=port)
