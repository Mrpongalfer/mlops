#!/bin/bash
# install.sh - Complete End-to-End Auto-Provisioning Script for Omnitide AI Suite
# This script auto-detects the environment and installs everything needed

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

# Detect OS and Architecture
detect_system() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l) ARCH="armv7" ;;
    esac
    
    log_info "Detected system: $OS/$ARCH"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install system dependencies based on OS
install_system_deps() {
    log_header "Installing System Dependencies"
    
    case "$OS" in
        linux)
            if command_exists apt-get; then
                # Debian/Ubuntu
                log_info "Installing dependencies for Debian/Ubuntu"
                sudo apt-get update
                sudo apt-get install -y curl wget git build-essential python3 python3-pip python3-venv
            elif command_exists yum; then
                # RHEL/CentOS/Fedora
                log_info "Installing dependencies for RHEL/CentOS/Fedora"
                sudo yum update -y
                sudo yum install -y curl wget git gcc python3 python3-pip
            elif command_exists pacman; then
                # Arch Linux
                log_info "Installing dependencies for Arch Linux"
                sudo pacman -Syu --noconfirm curl wget git base-devel python python-pip
            else
                log_warn "Unknown Linux distribution, continuing with manual checks"
            fi
            ;;
        darwin)
            # macOS
            log_info "Installing dependencies for macOS"
            if ! command_exists brew; then
                log_info "Installing Homebrew"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew update
            brew install curl wget git python@3.10
            ;;
        *)
            log_warn "Unsupported OS: $OS, continuing with manual checks"
            ;;
    esac
}

# Install Python and create virtual environment
setup_python() {
    log_header "Setting up Python Environment"
    
    # Check Python version
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version | awk '{print $2}')
        log_info "Found Python: $PYTHON_VERSION"
        
        # Check if version is >= 3.10
        if python3 -c "import sys; exit(0 if sys.version_info >= (3, 10) else 1)"; then
            log_success "Python version is compatible"
            PYTHON_CMD="python3"
        else
            log_warn "Python version is too old, need 3.10+"
            install_python310
        fi
    else
        log_warn "Python3 not found, installing"
        install_python310
    fi
    
    # Create virtual environment
    if [ ! -d ".venv" ]; then
        log_info "Creating virtual environment"
        $PYTHON_CMD -m venv .venv
    fi
    
    # Activate virtual environment
    source .venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip setuptools wheel
    
    log_success "Python environment ready"
}

# Install Python 3.10 if needed
install_python310() {
    case "$OS" in
        linux)
            if command_exists apt-get; then
                sudo apt-get install -y software-properties-common
                sudo add-apt-repository -y ppa:deadsnakes/ppa
                sudo apt-get update
                sudo apt-get install -y python3.10 python3.10-venv python3.10-pip
                PYTHON_CMD="python3.10"
            elif command_exists yum; then
                sudo yum install -y python310 python310-pip
                PYTHON_CMD="python3.10"
            fi
            ;;
        darwin)
            brew install python@3.10
            PYTHON_CMD="python3.10"
            ;;
    esac
}

# Install Poetry
install_poetry() {
    log_header "Installing Poetry"
    
    if command_exists poetry; then
        log_success "Poetry already installed"
        return
    fi
    
    log_info "Installing Poetry package manager"
    curl -sSL https://install.python-poetry.org | python3 -
    
    # Add Poetry to PATH
    export PATH="$HOME/.local/bin:$PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    
    # Configure Poetry
    poetry config virtualenvs.in-project true
    
    log_success "Poetry installed and configured"
}

# Install Docker
install_docker() {
    log_header "Installing Docker"
    
    if command_exists docker; then
        log_success "Docker already installed"
        return
    fi
    
    case "$OS" in
        linux)
            log_info "Installing Docker for Linux"
            curl -fsSL https://get.docker.com | sh
            sudo usermod -aG docker $USER
            sudo systemctl start docker
            sudo systemctl enable docker
            ;;
        darwin)
            log_info "Installing Docker Desktop for macOS"
            log_warn "Please install Docker Desktop manually from: https://www.docker.com/products/docker-desktop"
            ;;
    esac
    
    log_success "Docker installation completed"
}

# Install Ollama
install_ollama() {
    log_header "Installing Ollama"
    
    if command_exists ollama; then
        log_success "Ollama already installed"
    else
        log_info "Installing Ollama for local LLM inference"
        curl -fsSL https://ollama.ai/install.sh | sh
    fi
    
    # Start Ollama service
    if ! pgrep -x "ollama" > /dev/null; then
        log_info "Starting Ollama service"
        ollama serve &
        sleep 3
    fi
    
    # Pull the required model
    log_info "Pulling phi3:3.8b model (this may take a while)"
    ollama pull phi3:3.8b-mini-instruct-4k-q4_0
    
    log_success "Ollama installed and model ready"
}

# Install Tailscale
install_tailscale() {
    log_header "Installing Tailscale"
    
    if command_exists tailscale; then
        log_success "Tailscale already installed"
        return
    fi
    
    log_info "Installing Tailscale for secure networking"
    curl -fsSL https://tailscale.com/install.sh | sh
    
    log_success "Tailscale installed"
    log_info "To connect to Tailnet, run: sudo tailscale up"
}

# Install DVC
install_dvc() {
    log_header "Installing DVC"
    
    if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
    fi
    
    pip install dvc[s3]
    
    # Initialize DVC if not already done
    if [ ! -d ".dvc" ]; then
        log_info "Initializing DVC"
        dvc init --no-scm
    fi
    
    log_success "DVC installed and initialized"
}

# Install project dependencies
install_project_deps() {
    log_header "Installing Project Dependencies"
    
    # Activate virtual environment
    if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
    fi
    
    if [ -f "pyproject.toml" ] && command_exists poetry; then
        log_info "Installing dependencies with Poetry"
        poetry install
    elif [ -f "requirements.txt" ]; then
        log_info "Installing dependencies with pip"
        pip install -r requirements.txt
    else
        log_info "Installing core dependencies directly"
        pip install fastapi uvicorn scikit-learn pandas joblib dvc pydantic prometheus-client structlog rich pyyaml typer pytest pytest-cov ruff
    fi
    
    log_success "Project dependencies installed"
}

# Setup project structure
setup_project_structure() {
    log_header "Setting up Project Structure"
    
    # Create necessary directories
    mkdir -p data/raw data/processed models reports logs src tests .dvc
    
    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        log_info "Creating .env file from template"
        cp .env.example .env 2>/dev/null || cat > .env << 'EOF'
# Omnitide AI Suite Environment Configuration
DVC_REMOTE_URL=http://dvc-storage.tailnet-id.ts.net:9000
DVC_ACCESS_KEY_ID=
DVC_SECRET_ACCESS_KEY=
OLLAMA_MODEL_NAME=phi3:3.8b-mini-instruct-4k-q4_0
TAILSCALE_AUTH_KEY=
ENVIRONMENT=development
EOF
    fi
    
    # Create sample data if none exists
    if [ ! -f "data/raw/data.csv" ]; then
        log_info "Creating sample dataset"
        cat > data/raw/data.csv << 'EOF'
feature1,feature2,feature3,target
0.1,0.2,0.3,1
0.4,0.5,0.6,0
0.7,0.8,0.9,1
0.2,0.3,0.4,0
0.5,0.6,0.7,1
0.8,0.9,1.0,0
0.3,0.4,0.5,1
0.6,0.7,0.8,0
0.9,1.0,0.1,1
0.0,0.1,0.2,0
EOF
    fi
    
    # Make scripts executable
    chmod +x *.sh 2>/dev/null || true
    
    log_success "Project structure ready"
}

# Run initial model training
initial_training() {
    log_header "Running Initial Model Training"
    
    # Activate virtual environment
    if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
    fi
    
    # Run data processing and model training
    if [ -f "src/data_processor.py" ]; then
        log_info "Processing data"
        python src/data_processor.py data/raw/data.csv
    fi
    
    if [ -f "src/model_trainer.py" ]; then
        log_info "Training initial model"
        python src/model_trainer.py
    fi
    
    if [ -f "src/model_evaluator.py" ]; then
        log_info "Evaluating model"
        python src/model_evaluator.py models/latest_model.joblib models/preprocessor.joblib data/raw/data.csv
    fi
    
    log_success "Initial training completed"
}

# Run system tests
run_tests() {
    log_header "Running System Tests"
    
    # Activate virtual environment
    if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
    fi
    
    # Run tests using the CLI if available
    if [ -f "omnitide.py" ]; then
        log_info "Running tests via CLI"
        python omnitide.py test
    elif command_exists pytest; then
        log_info "Running tests with pytest"
        pytest tests/ -v
    else
        log_warn "No test runner available, skipping tests"
    fi
    
    log_success "Tests completed"
}

# Final validation
validate_installation() {
    log_header "Validating Installation"
    
    # Check all required commands
    local all_good=true
    
    for cmd in python3 pip; do
        if command_exists "$cmd"; then
            log_success "$cmd is available"
        else
            log_error "$cmd is not available"
            all_good=false
        fi
    done
    
    # Check optional but recommended tools
    for cmd in docker ollama tailscale dvc poetry; do
        if command_exists "$cmd"; then
            log_success "$cmd is available"
        else
            log_warn "$cmd is not available (optional)"
        fi
    done
    
    # Check Python modules
    if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
    fi
    
    for module in fastapi pandas sklearn joblib; do
        if python -c "import $module" 2>/dev/null; then
            log_success "Python module '$module' is available"
        else
            log_warn "Python module '$module' is not available"
        fi
    done
    
    # Test the application
    if [ -f "main.py" ]; then
        log_info "Testing application startup"
        timeout 10s python -c "
import sys
sys.path.append('src')
try:
    from main import app
    print('✅ Application imports successfully')
except Exception as e:
    print(f'⚠️  Application import failed: {e}')
" || log_warn "Application test timed out"
    fi
    
    if $all_good; then
        log_success "Installation validation passed!"
    else
        log_warn "Some issues detected, but installation may still work"
    fi
}

# Show usage instructions
show_usage() {
    log_header "Installation Complete!"
    
    echo -e "${GREEN}🎉 Omnitide AI Suite is now installed and ready to use!${NC}\n"
    
    echo -e "${CYAN}Quick Start Commands:${NC}"
    echo -e "  ${YELLOW}# Activate virtual environment${NC}"
    echo -e "  source .venv/bin/activate"
    echo -e ""
    echo -e "  ${YELLOW}# Start the API server${NC}"
    echo -e "  ./intelligent_entrypoint.sh api"
    echo -e "  ${YELLOW}# OR${NC}"
    echo -e "  python omnitide.py run"
    echo -e ""
    echo -e "  ${YELLOW}# Interactive mode${NC}"
    echo -e "  python omnitide.py interactive"
    echo -e ""
    echo -e "  ${YELLOW}# Run self-healing${NC}"
    echo -e "  python omnitide.py agent heal"
    echo -e ""
    echo -e "  ${YELLOW}# Run tests${NC}"
    echo -e "  python omnitide.py test"
    echo -e ""
    
    echo -e "${CYAN}Configuration:${NC}"
    echo -e "  • Edit ${YELLOW}.env${NC} file for environment-specific settings"
    echo -e "  • Edit ${YELLOW}config.yaml${NC} for application configuration"
    echo -e ""
    
    echo -e "${CYAN}Documentation:${NC}"
    echo -e "  • ${YELLOW}README.md${NC} - General overview"
    echo -e "  • ${YELLOW}README_INTELLIGENT.md${NC} - Detailed intelligent features"
    echo -e ""
    
    echo -e "${GREEN}Happy coding with Omnitide AI Suite! 🚀${NC}"
}

# Main installation flow
main() {
    log_header "Omnitide AI Suite - Complete Auto-Installer"
    
    echo -e "${CYAN}This script will install and configure everything needed for the Omnitide AI Suite.${NC}"
    echo -e "${CYAN}Detected system: $(uname -s)/$(uname -m)${NC}\n"
    
    # Check if running as root (not recommended)
    if [ "$EUID" -eq 0 ]; then
        log_warn "Running as root is not recommended. Consider running as a regular user."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Detect system
    detect_system
    
    # Install system dependencies
    install_system_deps
    
    # Setup Python environment
    setup_python
    
    # Install package managers and tools
    install_poetry
    install_docker
    install_ollama
    install_tailscale
    install_dvc
    
    # Install project dependencies
    install_project_deps
    
    # Setup project structure
    setup_project_structure
    
    # Run initial training
    initial_training
    
    # Run tests
    run_tests
    
    # Validate installation
    validate_installation
    
    # Show usage instructions
    show_usage
}

# Handle script arguments
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    case "${1:-}" in
        --help|-h)
            echo "Omnitide AI Suite Auto-Installer"
            echo "Usage: $0 [--help]"
            echo ""
            echo "This script automatically installs and configures the complete Omnitide AI Suite."
            echo "It will:"
            echo "  - Install system dependencies"
            echo "  - Setup Python environment"
            echo "  - Install Poetry, Docker, Ollama, Tailscale, DVC"
            echo "  - Install project dependencies"
            echo "  - Setup project structure"
            echo "  - Run initial model training"
            echo "  - Validate installation"
            exit 0
            ;;
        *)
            main "$@"
            ;;
    esac
fi
