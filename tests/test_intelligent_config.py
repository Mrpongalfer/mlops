# tests/test_intelligent_config.py
import pytest
from src.intelligent_config import IntelligentConfig

@pytest.fixture
def intelligent_config():
    """Fixture for IntelligentConfig."""
    return IntelligentConfig()

def test_config_initialization(intelligent_config):
    """Test that the configuration initializes correctly."""
    assert intelligent_config is not None
    assert intelligent_config.base_path.is_dir()

def test_get_dynamic_config(intelligent_config):
    """Test that dynamic configuration is generated."""
    config = intelligent_config.get_dynamic_config()
    assert "project" in config
    assert "api" in config
    assert "paths" in config
    assert "environment" in config
    assert config["project"]["name"] == "omnitide-ai-suite"

def test_environment_detection(intelligent_config):
    """Test that environment detection returns expected keys."""
    env_info = intelligent_config.detect_environment()
    assert "python_version" in env_info
    assert "platform" in env_info
    assert "has_gpu" in env_info
    assert "has_docker" in env_info

def test_project_healing(intelligent_config, tmp_path):
    """Test the project healing functionality."""
    # Point base_path to a temporary directory to simulate a broken environment
    intelligent_config.base_path = tmp_path
    
    # Ensure directories don't exist initially
    assert not (tmp_path / "data" / "raw").exists()
    
    actions = intelligent_config.heal_project()
    
    # Check that directories were created
    assert (tmp_path / "data" / "raw").exists()
    assert (tmp_path / "models").exists()
    
    # Check that a sample data file was created
    assert (tmp_path / "data" / "raw" / "data.csv").exists()
    
    assert "Created directory: data/raw" in actions
    assert "Created sample data file" in actions

    # Simulate a broken environment
    broken_path = tmp_path / "missing_dir"
    assert not broken_path.exists()

    # Trigger healing
    intelligent_config.heal_project()

    # Verify the environment is healed
    assert broken_path.exists()

def test_agent_orchestration(intelligent_config):
    """Test the agent task orchestration."""
    # Test heal task
    heal_result = intelligent_config.orchestrate_agent_task("heal")
    assert heal_result["success"]
    assert isinstance(heal_result["result"], list)

    # Test detect task
    detect_result = intelligent_config.orchestrate_agent_task("detect")
    assert detect_result["success"]
    assert "python_version" in detect_result["result"]

    # Test unknown task
    unknown_result = intelligent_config.orchestrate_agent_task("non_existent_task")
    assert not unknown_result["success"]
    assert "Unknown task" in unknown_result["error"]

    # Simulate an agent task
    result = intelligent_config.orchestrate_task("heal")

    # Verify the task was executed successfully
    assert result == "Task 'heal' executed successfully."
