# src/intelligent_config.py
import os
import sys
import subprocess
import importlib
import json
from pathlib import Path
from typing import Dict, Any, Optional, List
import logging

# Ensure torch is optional
try:
    import torch
except ImportError:
    torch = None

# Finalize `torch` handling and ensure consistent return type
# Ensure `torch` is explicitly checked before accessing `cuda`
if torch is not None:
    def check_torch_cuda() -> bool:
        cuda_available = getattr(torch, 'cuda', None)
        return bool(cuda_available and cuda_available.is_available())
else:
    def check_torch_cuda() -> bool:
        return False

class IntelligentConfig:
    """Dynamic configuration system that adapts to environment and handles dependencies."""
    
    def __init__(self):
        self.base_path = Path(__file__).parent.parent
        self.config_cache = {}
        self.available_modules = {}
        self.setup_logging()
        
    def setup_logging(self):
        """Setup intelligent logging that works with or without structlog."""
        try:
            import structlog
            self.logger = structlog.get_logger()
            self.use_structlog = True
        except ImportError:
            logging.basicConfig(level=logging.INFO)
            self.logger = logging.getLogger(__name__)
            self.use_structlog = False
    
    def log_info(self, message: str, **kwargs):
        """Intelligent logging that adapts to available logger."""
        if self.use_structlog:
            self.logger.info(message, **kwargs)
        else:
            self.logger.info(f"{message} {kwargs}")
    
    def check_module_availability(self, module_name: str) -> bool:
        """Check if a module is available and cache the result."""
        if module_name in self.available_modules:
            return self.available_modules[module_name]
        
        try:
            importlib.import_module(module_name)
            self.available_modules[module_name] = True
            return True
        except ImportError:
            self.available_modules[module_name] = False
            return False

    def check_command_availability(self, command: str) -> bool:
        """Check if a command line tool is available."""
        try:
            subprocess.run([command, "--version"], 
                         capture_output=True, 
                         check=True, 
                         timeout=5)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            return False

    def get_dynamic_config(self) -> Dict[str, Any]:
        """Generate dynamic configuration based on environment."""
        env_info = self.detect_environment()
        
        config = {
            "project": {
                "name": "omnitide-ai-suite",
                "version": "1.0.0",
                "description": "Dynamic MLOps & LLM Platform"
            },
            "api": {
                "host": "0.0.0.0",
                "port": env_info.get("available_ports", [8000])[0],
                "reload": env_info.get("dev_mode", True)
            },
            "paths": self.get_dynamic_paths(),
            "data": self.get_data_config(),
            "models": self.get_model_config(),
            "llm": self.get_llm_config(),
            "monitoring": self.get_monitoring_config(),
            "environment": env_info
        }
        
        return config

    def get_dynamic_paths(self) -> Dict[str, str]:
        """Get dynamic paths based on current environment."""
        base = self.base_path
        
        paths = {
            "base": str(base),
            "data_dir": str(base / "data"),
            "models_dir": str(base / "models"),
            "reports_dir": str(base / "reports"),
            "logs_dir": str(base / "logs"),
            "config_file": str(base / "config.yaml")
        }
        
        # Create directories if they don't exist
        for key, path in paths.items():
            if key != "config_file" and key != "base":
                Path(path).mkdir(exist_ok=True)
                
        return paths

    def get_data_config(self) -> Dict[str, Any]:
        """Get data configuration with fallbacks."""
        data_path = self.base_path / "data"
        
        return {
            "raw_data": str(data_path / "raw"),
            "processed_data": str(data_path / "processed"),
            "sample_size": 1000,
            "validation_split": 0.2,
            "test_split": 0.1
        }

    def get_model_config(self) -> Dict[str, Any]:
        """Get model configuration with intelligent defaults."""
        has_gpu = self.detect_gpu_availability()
        
        return {
            "type": "sklearn_ensemble",
            "algorithm": "RandomForestClassifier",
            "parameters": {
                "n_estimators": 100,
                "random_state": 42,
                "n_jobs": -1 if not has_gpu else 1
            },
            "use_gpu": has_gpu,
            "model_path": str(self.base_path / "models" / "model.joblib")
        }

    def get_llm_config(self) -> Dict[str, Any]:
        """Get LLM configuration with Ollama integration."""
        has_ollama = self.check_command_availability("ollama")
        
        # Try to detect available models if Ollama is installed
        available_model = self.detect_available_ollama_model() if has_ollama else "phi3:mini"
        
        config = {
            "enabled": has_ollama,
            "provider": "ollama" if has_ollama else "none",
            "model": available_model,
            "api_base": "http://localhost:11434",
            "temperature": 0.7,
            "max_tokens": 2000
        }
        
        if not has_ollama:
            config["fallback_message"] = "LLM features disabled - Ollama not available"
            
        return config

    def detect_available_ollama_model(self) -> str:
        """Detect which Ollama model is available."""
        try:
            result = subprocess.run(["ollama", "list"], 
                                  capture_output=True, 
                                  text=True, 
                                  timeout=5)
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                if len(lines) > 1:  # Skip header line
                    # Get the first available model
                    first_model = lines[1].split()[0] if lines[1].split() else "phi3:mini"
                    return first_model
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            pass
        
        # Default fallback models in order of preference
        fallback_models = ["phi3:mini", "llama3.2:3b", "llama3.1:8b", "mistral:7b"]
        for model in fallback_models:
            try:
                result = subprocess.run(["ollama", "show", model], 
                                      capture_output=True, 
                                      timeout=3)
                if result.returncode == 0:
                    return model
            except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
                continue
                
        return "phi3:mini"  # Ultimate fallback

    def get_monitoring_config(self) -> Dict[str, Any]:
        """Get monitoring configuration."""
        has_prometheus = self.check_module_availability("prometheus_client")
        
        return {
            "metrics_enabled": has_prometheus,
            "metrics_port": 9090,
            "logging_level": "INFO",
            "health_check_interval": 30
        }

    def detect_gpu_availability(self) -> bool:
        """Detect if GPU is available for ML tasks."""
        try:
            # Check for NVIDIA GPU
            result = subprocess.run(["nvidia-smi"], 
                                  capture_output=True, 
                                  check=True, 
                                  timeout=5)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            pass
            
        # Check for other GPU types (AMD, Intel)
        try:
            return check_torch_cuda()
        except ImportError:
            pass
            
        return False

    def detect_environment(self) -> Dict[str, Any]:
        """Detect current environment and capabilities."""
        env_info = {
            "python_version": f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
            "platform": sys.platform,
            "working_directory": str(Path.cwd()),
            "has_gpu": self.detect_gpu_availability(),
            "available_ports": self.get_available_ports(),
            "dev_mode": os.getenv("ENVIRONMENT", "development") == "development"
        }
        
        # Check for important tools
        tools = ["git", "docker", "ollama", "dvc"]
        for tool in tools:
            env_info[f"has_{tool}"] = self.check_command_availability(tool)
        
        # Check for Python packages
        packages = ["fastapi", "pandas", "sklearn", "torch", "tensorflow"]
        for package in packages:
            env_info[f"has_{package}"] = self.check_module_availability(package)
            
        return env_info

    def get_available_ports(self, start_port: int = 8000, num_ports: int = 10) -> List[int]:
        """Find available ports starting from start_port."""
        import socket
        available_ports = []
        
        for port in range(start_port, start_port + num_ports):
            try:
                with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                    s.bind(('localhost', port))
                    available_ports.append(port)
            except OSError:
                continue
                
        return available_ports if available_ports else [start_port]

    def heal_project(self) -> List[str]:
        """Perform project healing and return list of actions taken."""
        actions = []
        
        # Create missing directories
        required_dirs = ["data/raw", "data/processed", "models", "reports", "logs"]
        for dir_path in required_dirs:
            full_path = self.base_path / dir_path
            if not full_path.exists():
                full_path.mkdir(parents=True, exist_ok=True)
                actions.append(f"Created directory: {dir_path}")
        
        # Install missing critical dependencies
        critical_deps = ["fastapi", "uvicorn", "pandas", "scikit-learn"]
        missing_deps = [dep for dep in critical_deps if not self.check_module_availability(dep)]
        
        if missing_deps:
            try:
                subprocess.run([sys.executable, "-m", "pip", "install"] + missing_deps, 
                             check=True, capture_output=True)
                actions.append(f"Installed missing dependencies: {', '.join(missing_deps)}")
            except subprocess.CalledProcessError as e:
                actions.append(f"Failed to install dependencies: {e}")
        
        # Create sample data if missing
        data_file = self.base_path / "data" / "raw" / "data.csv"
        if not data_file.exists():
            self.create_sample_data()
            actions.append("Created sample data file")
        
        # Validate configuration
        try:
            config = self.get_dynamic_config()
            actions.append("Configuration validated successfully")
        except Exception as e:
            actions.append(f"Configuration validation failed: {e}")
        
        return actions

    def create_sample_data(self):
        """Create sample data for testing."""
        try:
            import pandas as pd
            import numpy as np
            
            # Generate sample data
            np.random.seed(42)
            n_samples = 1000
            
            data = {
                'feature_1': np.random.normal(0, 1, n_samples),
                'feature_2': np.random.normal(0, 1, n_samples),
                'feature_3': np.random.uniform(-1, 1, n_samples),
                'target': np.random.choice([0, 1], n_samples)
            }
            
            df = pd.DataFrame(data)
            
            # Save sample data
            data_dir = self.base_path / "data" / "raw"
            data_dir.mkdir(parents=True, exist_ok=True)
            df.to_csv(data_dir / "data.csv", index=False)
            
        except ImportError:
            # Create basic CSV without pandas
            data_dir = self.base_path / "data" / "raw"
            data_dir.mkdir(parents=True, exist_ok=True)
            
            with open(data_dir / "data.csv", "w") as f:
                f.write("feature_1,feature_2,feature_3,target\n")
                f.write("0.1,0.2,0.3,1\n")
                f.write("0.4,0.5,0.6,0\n")
                f.write("0.7,0.8,0.9,1\n")

    def orchestrate_agent_task(self, task_name: str, params: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Orchestrate various agent tasks."""
        if params is None:
            params = {}
            
        try:
            if task_name == "heal":
                actions = self.heal_project()
                return {"success": True, "result": actions}
            
            elif task_name == "detect":
                env_info = self.detect_environment()
                return {"success": True, "result": env_info}
            
            elif task_name == "adapt":
                config = self.get_dynamic_config()
                return {"success": True, "result": config}
            
            elif task_name == "install_deps":
                missing_deps = params.get("dependencies", [])
                try:
                    if missing_deps:
                        subprocess.run([sys.executable, "-m", "pip", "install"] + missing_deps, 
                                     check=True, capture_output=True)
                        return {"success": True, "result": f"Installed: {', '.join(missing_deps)}"}
                    else:
                        return {"success": True, "result": "No dependencies to install"}
                except subprocess.CalledProcessError as e:
                    return {"success": False, "error": f"Installation failed: {e}"}
            
            else:
                return {"success": False, "error": f"Unknown task: {task_name}"}
                
        except Exception as e:
            return {"success": False, "error": str(e)}


# Global instance for easy access
intelligent_config = IntelligentConfig()

# Convenience functions
def get_config() -> Dict[str, Any]:
    """Get dynamic configuration"""
    return intelligent_config.get_dynamic_config()

def detect_env() -> Dict[str, Any]:
    """Detect environment"""
    return intelligent_config.detect_environment()

def heal_project() -> List[str]:
    """Heal project"""
    return intelligent_config.heal_project()
