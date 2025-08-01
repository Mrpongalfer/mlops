#!/bin/bash
# intelligent_entrypoint.sh - Dynamic, self-healing entrypoint inspired by your DUO system
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[OMNITIDE]${NC} INFO: $1"; }
log_success() { echo -e "${GREEN}[OMNITIDE]${NC} SUCCESS: $1"; }
log_warn() { echo -e "${YELLOW}[OMNITIDE]${NC} WARNING: $1"; }
log_error() { echo -e "${RED}[OMNITIDE]${NC} ERROR: $1"; }

# Load .env if it exists
if [ -f .env ]; then
    log_info "Loading environment variables from .env"
    export $(grep -v '^#' .env | xargs) 2>/dev/null || true
fi

# Auto-detect Python executable
detect_python() {
    local python_candidates=("python3.10" "python3.11" "python3" "python")
    for py in "${python_candidates[@]}"; do
        if command -v "$py" &> /dev/null; then
            echo "$py"
            return 0
        fi
    done
    echo "python3"
}

PYTHON_CMD=$(detect_python)
log_info "Using Python: $PYTHON_CMD"

# Auto-detect virtual environment
detect_venv() {
    local venv_paths=(".venv/bin/activate" "venv/bin/activate" "$VIRTUAL_ENV/bin/activate")
    for venv in "${venv_paths[@]}"; do
        if [ -f "$venv" ]; then
            echo "$venv"
            return 0
        fi
    done
    return 1
}

# Activate virtual environment if available
if VENV_ACTIVATE=$(detect_venv); then
    log_info "Activating virtual environment: $VENV_ACTIVATE"
    source "$VENV_ACTIVATE"
    PYTHON_CMD="python"
else
    log_warn "No virtual environment detected, using system Python"
fi

# Auto-heal project
log_info "Running auto-healing checks..."
$PYTHON_CMD -c "
from src.intelligent_config import IntelligentConfig
config = IntelligentConfig()
actions = config.heal_project()
print(f'Healing completed: {len(actions)} actions performed')
for action in actions:
    print(f'  ✓ {action}')
" 2>/dev/null || log_warn "Auto-healing failed, continuing anyway..."

# Install missing dependencies automatically
install_dependencies() {
    log_info "Checking and installing dependencies..."
    
    # Check if requirements.txt exists
    if [ -f requirements.txt ]; then
        log_info "Installing from requirements.txt..."
        $PYTHON_CMD -m pip install -r requirements.txt --quiet --disable-pip-version-check || {
            log_warn "Some packages failed to install, continuing..."
        }
    fi
    
    # Install core packages if not available
    local core_packages=("fastapi" "uvicorn" "pandas" "scikit-learn" "joblib" "pyyaml" "rich" "typer" "structlog")
    for package in "${core_packages[@]}"; do
        $PYTHON_CMD -c "import $package" 2>/dev/null || {
            log_info "Installing missing package: $package"
            $PYTHON_CMD -m pip install "$package" --quiet --disable-pip-version-check || true
        }
    done
}

# Function to check service health
check_service_health() {
    local url="$1"
    local retries=5
    local count=0
    
    while [ $count -lt $retries ]; do
        if curl -s -f "$url/v1/health" >/dev/null 2>&1; then
            return 0
        fi
        count=$((count + 1))
        sleep 1
    done
    return 1
}

# Dynamic mode detection
detect_mode() {
    if [ -n "$OMNITIDE_MODE" ]; then
        echo "$OMNITIDE_MODE"
    elif [ "$1" = "api" ] || [ "$1" = "server" ]; then
        echo "api"
    elif [ "$1" = "cli" ] || [ "$1" = "interactive" ]; then
        echo "cli"
    elif [ "$1" = "agent" ]; then
        echo "agent"
    elif [ "$1" = "heal" ]; then
        echo "heal"
    elif [ -f "main.py" ]; then
        echo "api"
    else
        echo "cli"
    fi
}

# Install dependencies
install_dependencies

# Ensure Tailscale is running
log_info "Checking Tailscale service..."
if ! pgrep -x "tailscaled" > /dev/null; then
    log_info "Starting Tailscale daemon..."
    sudo tailscaled --state=/var/lib/tailscale/tailscaled.state &
    sleep 2
fi

log_info "Joining Tailscale network..."
if [ -z "$TAILSCALE_AUTH_KEY" ]; then
    log_error "TAILSCALE_AUTH_KEY is not set. Cannot join Tailnet."
    exit 1
fi
sudo tailscale up --authkey=$TAILSCALE_AUTH_KEY --hostname=omnitide-suite || {
    log_error "Failed to join Tailscale network."
    exit 1
}

# Ensure Ollama service is running
log_info "Checking Ollama service..."
if ! pgrep -x "ollama" > /dev/null; then
    log_info "Starting Ollama server..."
    ollama serve &
    sleep 2
fi

# Verify Ollama service health
log_info "Verifying Ollama service health..."
retry_with_backoff() {
    local max_attempts=${1:-5}
    local delay=${2:-1}
    local attempt=1
    local command="$3"

    while [ $attempt -le $max_attempts ]; do
        if $command; then
            return 0
        fi
        log_warn "Attempt $attempt failed. Retrying in $delay seconds..."
        sleep $delay
        delay=$((delay * 2))
        attempt=$((attempt + 1))
    done
    log_error "Command failed after $max_attempts attempts."
    return 1
}

retry_with_backoff 10 5 "curl -sS -X POST http://localhost:11434/api/generate -d '{\"model\": \"phi3:3.8b-mini-instruct-4k-q4_0\", \"prompt\":\"Hi\"}' > /dev/null" || {
    log_error "Ollama service is not ready."
    exit 1
}

# Determine execution mode
MODE=$(detect_mode "$1")
log_info "Execution mode: $MODE"

case "$MODE" in
    "api"|"server")
        log_info "Starting Omnitide AI Suite API server..."
        
        # Try different main files
        if [ -f "main.py" ]; then
            MAIN_FILE="main.py"
        elif [ -f "main_simple.py" ]; then
            MAIN_FILE="main_simple.py"
        else
            log_error "No main application file found"
            exit 1
        fi
        
        # Get dynamic port
        PORT=$(python3 -c "
from src.intelligent_config import IntelligentConfig
config = IntelligentConfig()
dynamic_config = config.get_dynamic_config()
print(dynamic_config.get('api', {}).get('port', 8000))
" 2>/dev/null || echo "8000")
        
        log_info "Starting server on port $PORT using $MAIN_FILE"
        
        # Start with uvicorn or fallback to python
        if command -v uvicorn &> /dev/null; then
            MODULE_NAME=$(basename "$MAIN_FILE" .py)
            exec uvicorn "${MODULE_NAME}:app" --host 0.0.0.0 --port "$PORT" --reload
        else
            exec $PYTHON_CMD "$MAIN_FILE"
        fi
        ;;
        
    "cli"|"interactive")
        log_info "Starting interactive CLI mode..."
        if [ -f "omnitide.py" ]; then
            exec $PYTHON_CMD omnitide.py "$@"
        else
            log_error "CLI not available"
            exit 1
        fi
        ;;
        
    "agent")
        log_info "Starting agent mode..."
        AGENT_SCRIPT="${2:-src/intelligent_config.py}"
        exec $PYTHON_CMD "$AGENT_SCRIPT" "${@:3}"
        ;;
        
    "heal")
        log_info "Running healing mode..."
        $PYTHON_CMD -c "
from src.intelligent_config import IntelligentConfig
config = IntelligentConfig()
actions = config.heal_project()
print('🔧 Project healing completed!')
for action in actions:
    print(f'  ✅ {action}')
"
        ;;
        
    *)
        if [ $# -gt 0 ]; then
            log_info "Executing custom command: $*"
            exec "$@"
        else
            log_info "No specific mode requested, starting API server..."
            exec "$0" api
        fi
        ;;
esac
