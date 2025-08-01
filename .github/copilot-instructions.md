<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Omnitide AI Suite Development Guidelines

## Project Overview
This is the Omnitide AI Suite - a comprehensive MLOps and LLM platform that integrates:
- Automated CI/CD pipelines with GitHub Actions
- Data and model versioning with DVC
- Local LLM inference using Ollama (phi3:3.8b model)
- Secure networking via Tailscale
- FastAPI-based model serving
- Prometheus metrics and monitoring
- Docker containerization

## Code Style and Standards
- Use Python 3.10+ features and type hints
- Follow PEP 8 style guidelines
- Use structured logging with `structlog`
- Implement proper error handling and validation
- Write comprehensive tests with pytest
- Use Pydantic for data validation
- Follow the existing project structure and configuration patterns

## Key Components
- **Data Processing**: `src/data_processor.py` - handles data validation and preprocessing
- **Model Training**: `src/model_trainer.py` - trains ML models using scikit-learn
- **Model Evaluation**: `src/model_evaluator.py` - evaluates model performance
- **LLM Agent**: `src/llm_agent.py` - interfaces with Ollama for report generation
- **API Server**: `main.py` - FastAPI application for model serving
- **CLI Tool**: `omnitide.py` - Typer-based CLI for project management

## Configuration
- All configuration is centralized in `config.yaml`
- Environment variables are managed through `.env` files
- DVC configuration is in `.dvc/config`

## Development Workflow
1. Use the `omnitide` CLI for common tasks
2. Follow the CI/CD pipeline defined in `.github/workflows/main.yml`
3. Ensure all changes pass linting (`omnitide lint`) and tests (`omnitide test`)
4. Use DVC for data and model versioning
5. Integrate with Tailscale for secure networking

## Dependencies and Tools
- Poetry for dependency management
- Ruff for linting and formatting
- Pytest for testing
- DVC for data versioning
- Ollama for LLM inference
- Tailscale for networking
- Docker for containerization

When making changes, ensure compatibility with the existing architecture and maintain the seamless integration between all components.
