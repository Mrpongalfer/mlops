# Omnitide AI Suite - README

![Omnitide AI Suite](https://user-images.githubusercontent.com/12345/omnitide-banner.png)

**An intelligent, self-healing MLOps platform that combines machine learning workflows with large language model capabilities, featuring dynamic configuration, automated CI/CD, and secure networking.**

---

## 🌟 Key Features

### 🧠 Intelligent & Self-Healing Architecture
- **Dynamic Configuration**: Automatically adapts to your environment (OS, hardware, dependencies).
- **Self-Healing**: Auto-detects and fixes common issues like missing dependencies or directories.
- **Environment Detection**: Discovers available tools (`git`, `docker`, `ollama`) and capabilities.
- **Dependency Management**: Automatically installs missing critical Python packages.

### 🤖 LLM Integration
- **Local LLM Inference**: Built-in support for local LLMs via Ollama (defaults to `phi3:3.8b`).
- **Automated Reporting**: Generate AI-powered summaries of model performance metrics.
- **Agent-based Orchestration**: Use intelligent agents to perform complex tasks.

### 📊 End-to-End MLOps Pipeline
- **Data & Model Versioning**: DVC integration for reproducible experiments.
- **Automated ML Workflows**: Scripts for data processing, model training, and evaluation.
- **High-Performance Model Serving**: FastAPI-based REST API with health monitoring and Prometheus metrics.

### 🔒 Secure & Scalable by Design
- **Tailscale Integration**: Built for secure, zero-config networking across your devices.
- **Containerized Deployments**: Full Docker support for reproducible and scalable deployments.
- **Multi-environment Ready**: Handles development, staging, and production configurations seamlessly.

---

## 🚀 Quick Start

### One-Command Installation

**Option 1: Quick Install (Auto-selects model)**
```bash
curl -fsSL https://raw.githubusercontent.com/mrpongalfer/mlops/main/install.sh | bash
```
*Note: When piped from curl, this automatically selects `phi3:mini` for reliability*

**Option 2: Interactive Install (Choose your model)**
```bash
curl -fsSL https://raw.githubusercontent.com/mrpongalfer/mlops/main/install_interactive.sh | bash
```
*This provides a full interactive menu to select your preferred LLM model*

**Option 3: Manual Download for Full Control**
```bash
# Download and run locally for maximum interactivity
wget https://raw.githubusercontent.com/mrpongalfer/mlops/main/install.sh
chmod +x install.sh
./install.sh
```

### What Gets Installed

The installer automatically:
- ✅ Detects your OS and architecture
- ✅ Installs system dependencies (Python, Git, etc.)
- ✅ Sets up Python virtual environment
- ✅ Installs Poetry, Docker, Ollama, Tailscale, DVC
- ✅ Configures the complete Omnitide AI Suite
- ✅ Downloads your chosen LLM model
- ✅ Runs initial model training
- ✅ Validates the installation

### After Installation

Once installed, activate the environment and run the system:

```bash
# Activate the virtual environment
source .venv/bin/activate

# Start the API server
python main.py
# OR using the CLI tool
python omnitide.py run

# For intelligent mode with self-healing
python main_intelligent.py

# Interactive CLI mode
python omnitide.py interactive

# Run self-healing agent
python omnitide.py agent heal
```

### Development Setup

If you're developing or want to install manually:

```bash
# Clone the repository
git clone https://github.com/mrpongalfer/mlops.git
cd mlops

# Install with Poetry
poetry install

# Or install with pip
pip install -r requirements.txt

# Run the system
python main.py
```

### 3. Using the Intelligent Entrypoint (Recommended)

This is the smartest way to run the application. It auto-detects your environment, activates virtual environments, and runs pre-flight checks.

```bash
# Start the API server with auto-configuration and healing
./intelligent_entrypoint.sh api

# Run CLI commands in a managed environment
./intelligent_entrypoint.sh cli --help

# Trigger a manual project healing process
./intelligent_entrypoint.sh heal
```

## 🚀 Quick Start

### 🎯 One-Command Installation (Recommended)

The complete auto-installer handles everything - dependencies, environment setup, and validation:

```bash
# Download and run the complete installer
curl -fsSL https://raw.githubusercontent.com/mrpongalfer/mlops/main/install.sh | bash

# OR clone and install locally
git clone https://github.com/mrpongalfer/mlops.git
cd mlops
chmod +x install.sh
./install.sh
```

The installer will:
- ✅ Detect your system (Linux/macOS/Windows WSL)
- ✅ Install Python 3.10+, Poetry, Docker, Ollama, Tailscale, DVC
- ✅ Set up virtual environment and dependencies
- ✅ Pull LLM models and configure services
- ✅ Create project structure and sample data
- ✅ Run initial model training and tests
- ✅ Validate complete installation

### 🐳 Docker Deployment (Production)

For production environments, use Docker Compose:

```bash
# Complete production stack
docker-compose up -d

# Individual services
docker-compose up -d omnitide-api  # Just the API
docker-compose up -d prometheus grafana  # Monitoring stack
```

This provides:
- 🚀 **Omnitide API** on port 8000
- 📊 **Prometheus** monitoring on port 9090  
- 📈 **Grafana** dashboards on port 3000
- 💾 **MinIO** S3-compatible storage on port 9000
- 🔄 **Redis** caching on port 6379
- ⚡ **Nginx** load balancer on port 80

### 🛠️ Manual Installation

If you prefer manual setup:

```bash
# 1. Prerequisites
python --version  # Ensure Python 3.10+
pip install poetry

# 2. Install system tools
curl -fsSL https://ollama.ai/install.sh | sh
curl -fsSL https://tailscale.com/install.sh | sh

# 3. Install project dependencies
poetry install
# OR
pip install -r requirements.txt

# 4. Pull LLM model
ollama pull phi3:3.8b-mini-instruct-4k-q4_0

# 5. Initialize DVC
dvc init --no-scm
```

### 🚪 Using the Intelligent Entrypoint

The intelligent entrypoint auto-detects your environment and configures everything:

```bash
# Start API server with auto-configuration and healing
./intelligent_entrypoint.sh api

# Run CLI operations in managed environment
./intelligent_entrypoint.sh cli --help

# Trigger comprehensive project healing
./intelligent_entrypoint.sh heal

# Agent mode for advanced orchestration
./intelligent_entrypoint.sh agent
```

### 🎮 Enhanced CLI Operations

```bash
# Activate environment first
source .venv/bin/activate  # If using virtual env

# Interactive mode with dynamic capabilities detection
python omnitide.py interactive

# Core operations
python omnitide.py run      # Start API server
python omnitide.py test     # Run test suite
python omnitide.py lint     # Code quality checks

# Intelligent agent operations
python omnitide.py agent heal     # Auto-fix project issues
python omnitide.py agent detect   # Environment analysis
python omnitide.py agent adapt    # Configuration tuning

# Deployment operations
python omnitide.py deploy --target local    # Local deployment
python omnitide.py deploy --target docker   # Docker deployment
python omnitide.py deploy --target k8s      # Kubernetes deployment
```

---

## 🏗️ Architecture Overview

```
omnitide-ai-suite/
├── .dvc/                      # DVC configuration for data versioning
├── .github/                   # GitHub Actions for CI/CD
├── data/                      # Raw and processed data (tracked by DVC)
├── models/                    # Trained models and preprocessors (tracked by DVC)
├── reports/                   # Evaluation metrics and LLM-generated summaries
├── src/                       # Core source code
│   ├── intelligent_config.py  # 🧠 Core intelligence & self-healing system
│   ├── llm_agent.py           # 🤖 LLM interaction logic
│   ├── model_trainer.py       # 📈 ML model training script
│   ├── data_processor.py      # 📊 Data processing and validation
│   └── deployer.py            # 🚀 Deployment handler
├── tests/                     # Test suites for all components
├── main.py                    # 🌐 FastAPI application entrypoint
├── omnitide.py                # 🛠️ Typer-based CLI application
├── intelligent_entrypoint.sh  # 🚪 Smart entrypoint script for safe execution
├── Dockerfile                 # Docker configuration for containerization
├── config.yaml                # Base static configuration
└── pyproject.toml             # Python project definition and dependencies
```

---

## 🌐 API Endpoints

The FastAPI server exposes a comprehensive set of endpoints.

- `GET /`: API information and status.
- `GET /v1/health`: Detailed system health check.
- `GET /v1/ready`: Readiness check (verifies if the model is loaded).
- `POST /v1/predict`: Make predictions with the loaded model.
- `POST /v1/agent/execute`: Execute an intelligent agent task (e.g., `heal`, `detect`).
- `POST /v1/heal`: Trigger a manual self-healing process.
- `GET /metrics`: Export Prometheus metrics for monitoring.

---

## 🐳 Docker Deployment

Build and run the application in a containerized environment.

```bash
# Build the Docker image
docker build -t omnitide-ai-suite .

# Run the container
docker run -p 8000:8000 --name omnitide-app omnitide-ai-suite
```

For more advanced scenarios, including connecting to a Tailnet, refer to the `start.sh` script for an example of how to manage services within the container.

---

## 🔧 Troubleshooting

If you encounter issues, the built-in self-healing is your first line of defense.

```bash
# Run from the CLI
omnitide agent heal

# Or use the entrypoint script
./intelligent_entrypoint.sh heal
```

This will:
- Create missing directories.
- Install critical Python dependencies.
- Generate sample data if needed.
- Validate and report on the system's configuration.

---

## 🤝 Contributing

Contributions are welcome! Please follow the standard fork-and-pull-request workflow. Before submitting, ensure your changes pass all local checks:

```bash
omnitide lint
omnitide test
```

---

**Built with ❤️ by the Omnitide Team**

*Intelligent MLOps for the modern era.*
