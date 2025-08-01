# Multi-stage production-ready Dockerfile for Omnitide AI Suite
FROM ubuntu:22.04 as base

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3.10-dev \
    python3.10-venv \
    python3-pip \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry

# Install Ollama
RUN curl -fsSL https://ollama.ai/install.sh | sh

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Create non-root user
RUN groupadd -r omnitide && useradd -r -g omnitide -s /bin/bash omnitide

# Build stage
FROM base as builder

WORKDIR /app

# Copy dependency files
COPY pyproject.toml poetry.lock* ./
COPY requirements.txt* ./

# Configure Poetry and install dependencies
RUN poetry config virtualenvs.create false
RUN if [ -f "pyproject.toml" ]; then \
        poetry install --no-dev; \
    elif [ -f "requirements.txt" ]; then \
        pip install -r requirements.txt; \
    else \
        pip install fastapi uvicorn scikit-learn pandas joblib prometheus-client structlog rich pyyaml typer; \
    fi

# Production stage
FROM base as production

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Set up application directory
WORKDIR /app

# Copy application code
COPY . .

# Pull Ollama model (in background to not block build)
RUN (ollama serve &) && sleep 10 && ollama pull phi3:3.8b-mini-instruct-4k-q4_0 || echo "Ollama model pull failed, will retry at runtime"

# Set ownership and permissions
RUN chown -R omnitide:omnitide /app \
    && chmod +x *.sh

# Create necessary directories
RUN mkdir -p data/raw data/processed models reports logs \
    && chown -R omnitide:omnitide data models reports logs

# Create sample data
RUN echo "feature1,feature2,feature3,target" > data/raw/data.csv \
    && echo "0.1,0.2,0.3,1" >> data/raw/data.csv \
    && echo "0.4,0.5,0.6,0" >> data/raw/data.csv \
    && echo "0.7,0.8,0.9,1" >> data/raw/data.csv \
    && chown omnitide:omnitide data/raw/data.csv

# Switch to non-root user
USER omnitide

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose ports
EXPOSE 8000 11434

# Default command - use intelligent entrypoint
CMD ["./intelligent_entrypoint.sh", "api"]
