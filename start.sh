#!/bin/bash
# start.sh
set -e
retry_with_backoff() {
    local max_attempts=${1:-5}
    local delay=${2:-1}
    local attempt=1
    local command="$3"

    while [ $attempt -le $max_attempts ]; do
        if $command; then
            return 0
        fi
        echo "Attempt $attempt failed. Retrying in $delay seconds..." >&2
        sleep $delay
        delay=$((delay * 2))
        attempt=$((attempt + 1))
    done
    echo "Command failed after $max_attempts attempts." >&2
    return 1
}

# Check and install missing dependencies
check_and_install() {
    local package=$1
    if ! command -v $package &> /dev/null; then
        echo "$package is not installed. Installing..."
        sudo apt-get update && sudo apt-get install -y $package
    else
        echo "$package is already installed."
    fi
}

# Ensure required dependencies are installed
check_and_install tailscale
check_and_install curl
check_and_install poetry
check_and_install python3
check_and_install pip

# Install Python dependencies
if [ ! -f "poetry.lock" ]; then
    echo "poetry.lock not found. Installing dependencies..."
    poetry install
else
    echo "Dependencies already installed."
fi

# Ensure Tailscale is running
sudo systemctl start tailscaled || sudo tailscaled --state=/var/lib/tailscale/tailscaled.state &

echo "Joining Omnitide Tailnet with provided key..."
if [ -z "$TAILSCALE_AUTH_KEY" ]; then
    echo "TAILSCALE_AUTH_KEY is not set. Cannot join Tailnet."
    exit 1
fi
sleep 2

retry_with_backoff 10 5 "sudo tailscale up --authkey=$TAILSCALE_AUTH_KEY --hostname=ai-model-api"
echo "Tailnet connection established."

echo "Starting Ollama server..."
ollama serve &

retry_with_backoff 10 5 "curl -sS -X POST http://localhost:11434/api/generate -d '{\"model\": \"phi3:3.8b-mini-instruct-4k-q4_0\", \"prompt\":\"Hi\"}' > /dev/null"
echo "Ollama service is ready."

echo "Starting FastAPI application..."
poetry run uvicorn main:app --host 0.0.0.0 --port 8000
