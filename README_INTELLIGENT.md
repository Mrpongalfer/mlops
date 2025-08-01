# 🚀 Omnitide AI Suite - Dynamic MLOps & LLM Platform

An intelligent, self-healing MLOps platform that combines machine learning workflows with large language model capabilities, featuring dynamic configuration, automated CI/CD, and secure networking.

## 🌟 Key Features

### 🧠 Intelligent & Self-Healing Architecture
- **Dynamic Configuration**: Automatically adapts to your environment
- **Self-Healing**: Auto-detects and fixes common issues
- **Environment Detection**: Discovers available tools and capabilities
- **Dependency Management**: Automatically installs missing dependencies

### 🤖 LLM Integration
- **Ollama Integration**: Local LLM inference with phi3:3.8b model
- **Report Generation**: AI-powered insights and recommendations
- **Agent Orchestration**: Intelligent task automation

### 📊 MLOps Pipeline
- **Model Training**: Automated ML workflows with scikit-learn
- **Data Versioning**: DVC integration for reproducible datasets
- **Model Serving**: FastAPI-based REST API with health monitoring
- **Performance Metrics**: Prometheus integration for monitoring

### 🔒 Secure Networking
- **Tailscale Integration**: Secure mesh networking
- **Docker Support**: Containerized deployments
- **Multi-environment**: Development, staging, and production configs

## 🚀 Quick Start

### Using the Intelligent Entrypoint (Recommended)

The intelligent entrypoint automatically detects your environment and sets up everything needed:

```bash
# Start API server with auto-configuration
./intelligent_entrypoint.sh api

# Run CLI operations
./intelligent_entrypoint.sh cli

# Agent mode for orchestration
./intelligent_entrypoint.sh agent

# Self-healing mode
./intelligent_entrypoint.sh heal
```

### Using the Enhanced CLI

```bash
# Interactive mode with dynamic menus
python3 omnitide.py interactive

# Heal project issues
python3 omnitide.py agent heal

# Environment detection
python3 omnitide.py agent detect

# Deploy with intelligent configuration  
python3 omnitide.py deploy --target local

# Traditional commands
python3 omnitide.py run
python3 omnitide.py test
```

## 🧠 Intelligent Features

### Auto-Healing Capabilities

The system automatically:
- Creates missing directories
- Installs critical dependencies
- Generates sample data if missing
- Validates configuration
- Fixes common setup issues

### Environment Detection

Automatically detects:
- Python version and platform
- Available ports
- GPU availability
- Installed tools (git, docker, ollama, dvc)
- Python packages (fastapi, pandas, sklearn, etc.)
- Development vs production mode

### Dynamic Configuration

The system adapts configuration based on:
- Available hardware (CPU/GPU)
- Installed software
- Network conditions  
- Environment variables
- Resource constraints

## 🏗️ Architecture

```
omnitide-ai-suite/
├── src/
│   ├── intelligent_config.py    # 🧠 Core intelligence system
│   ├── llm_agent.py             # 🤖 LLM integration
│   ├── model_trainer.py         # 📈 ML training
│   ├── data_processor.py        # 📊 Data pipeline
│   └── deployer.py              # 🚀 Deployment
├── main.py                      # 🌐 FastAPI application
├── omnitide.py                  # 🛠️ Enhanced CLI
├── intelligent_entrypoint.sh    # 🚪 Smart entrypoint
└── config.yaml                  # ⚙️ Base configuration
```

## 🔧 API Endpoints

### Core Endpoints
- `GET /` - API information and status
- `GET /health` - Comprehensive health check
- `GET /health/detailed` - Detailed system status

### ML Endpoints  
- `POST /v1/predict` - Make predictions
- `POST /v1/train` - Train models
- `GET /v1/model/status` - Model information

### LLM Endpoints
- `POST /v1/llm/generate` - Generate text with LLM
- `POST /v1/llm/report` - Generate analysis reports

### Agent Endpoints
- `POST /v1/agent/execute` - Execute agent tasks
- `POST /v1/heal` - Trigger self-healing
- `GET /v1/environment` - Environment detection

### Monitoring
- `GET /metrics` - Prometheus metrics
- `GET /v1/logs` - System logs

## 🎯 Agent Tasks

The system supports various intelligent agent tasks:

```bash
# Project healing
python3 omnitide.py agent heal

# Environment detection  
python3 omnitide.py agent detect

# Configuration adaptation
python3 omnitide.py agent adapt

# System monitoring
python3 omnitide.py agent monitor

# Custom task execution
python3 omnitide.py agent custom-task --params '{"key": "value"}'
```

## 🐳 Docker Deployment

### Intelligent Docker Build

```bash
# Build with dynamic configuration
docker build -t omnitide-ai-suite .

# Run with port auto-detection
docker run -p 8000:8000 omnitide-ai-suite

# Deploy with CLI
python3 omnitide.py deploy --target docker
```

### Docker Compose (Recommended)

```bash
# Start all services
docker-compose up -d

# Scale dynamically
docker-compose up --scale api=3
```

## 🔗 Tailscale Integration

Secure networking with Tailscale:

```bash
# Setup Tailscale networking
tailscale up --hostname omnitide-suite

# Access from anywhere in your tailnet
curl http://omnitide-suite:8000/health
```

## 📊 Monitoring & Observability

### Prometheus Metrics

- API request metrics
- Model performance metrics  
- System resource usage
- Custom business metrics

### Health Monitoring

The system provides comprehensive health checks:
- Database connectivity
- External service availability
- Resource utilization
- Model status
- LLM connectivity

## 🧪 Testing

```bash
# Run all tests
python3 omnitide.py test

# Run specific test suites
pytest tests/test_intelligent_config.py
pytest tests/test_agents.py

# Coverage reporting
pytest --cov=src tests/
```

## 🔧 Configuration

### Intelligent Configuration

The system uses intelligent configuration that adapts automatically:

- **Environment Detection**: Automatically detects capabilities
- **Resource Optimization**: Adjusts based on available resources
- **Fallback Handling**: Graceful degradation when services unavailable
- **Hot Reloading**: Configuration updates without restart

### Manual Configuration

For advanced users, configurations can be customized in:
- `config.yaml` - Base configuration
- Environment variables
- CLI parameters
- API configuration endpoints

## 🚨 Troubleshooting

### Self-Healing First
```bash
# Let the system fix itself first
python3 omnitide.py agent heal
```

### Common Issues

**Missing Dependencies**
```bash
# Auto-install missing packages
python3 omnitide.py agent heal
```

**Port Conflicts**
```bash
# Auto-detect available ports
python3 omnitide.py agent detect
```

**Configuration Issues**
```bash
# Reset and adapt configuration
python3 omnitide.py agent adapt
```

**Environment Problems**
```bash
# Full environment analysis
python3 omnitide.py interactive
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the test suite: `python3 omnitide.py test`
5. Run healing checks: `python3 omnitide.py agent heal`
6. Submit a pull request

## 📝 License

MIT License - see LICENSE file for details.

## 🔗 Links

- [Documentation](docs/)
- [API Reference](docs/api.md)
- [Deployment Guide](docs/deployment.md)
- [Contributing Guide](CONTRIBUTING.md)

---

**Built with ❤️ by the Omnitide Team**

*Intelligent MLOps for the modern era*
