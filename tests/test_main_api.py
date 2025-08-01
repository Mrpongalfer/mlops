# tests/test_main_api.py
import pytest
from fastapi.testclient import TestClient
from main import app

@pytest.fixture
def client():
    """Fixture for the FastAPI test client."""
    return TestClient(app)

def test_health_check(client):
    """Test the health check endpoint."""
    response = client.get("/v1/health")
    assert response.status_code == 200
    json_response = response.json()
    assert json_response["status"] == "ok"
    assert "environment" in json_response
    assert "healing_actions" in json_response

def test_readiness_check(client):
    """Test the readiness check endpoint."""
    response = client.get("/v1/ready")
    assert response.status_code == 200
    assert response.json()["status"] == "ready"

def test_root_endpoint(client):
    """Test the root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    assert "Omnitide AI Suite API" in response.json()["message"]

def test_prediction_endpoint(client):
    """Test the prediction endpoint with valid data."""
    # This test assumes a model is loaded or a fallback is in place.
    # The dummy model in main.py should handle this.
    response = client.post("/v1/predict", json={"data": [[1.0, 2.0, 3.0]]})
    assert response.status_code == 200
    json_response = response.json()
    assert "prediction" in json_response or "fallback_prediction" in json_response

def test_prediction_endpoint_invalid_data(client):
    """Test the prediction endpoint with invalid data."""
    response = client.post("/v1/predict", json={"invalid_key": "some_value"})
    assert response.status_code == 422  # Unprocessable Entity

def test_agent_execution_endpoint(client):
    """Test the agent execution endpoint."""
    response = client.post("/v1/agent/execute", json={"task_name": "detect"})
    assert response.status_code == 200
    json_response = response.json()
    assert json_response["success"]
    assert "python_version" in json_response["result"]

def test_healing_endpoint(client):
    """Test the self-healing endpoint."""
    response = client.post("/v1/heal")
    assert response.status_code == 200
    json_response = response.json()
    assert "actions" in json_response
    assert isinstance(json_response["actions"], list)

def test_metrics_endpoint(client):
    """Test the Prometheus metrics endpoint."""
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "api_requests_total" in response.text
