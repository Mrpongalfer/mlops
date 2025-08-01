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
    
    # Try multiple installation methods
    local poetry_installed=false
    
    # Method 1: Official installer
    if curl -fsSL --connect-timeout 10 https://install.python-poetry.org | python3 -; then
        poetry_installed=true
        log_success "Poetry installed via official installer"
    else
        log_warn "Official Poetry installer failed, trying alternative methods..."
        
        # Method 2: pip install (fallback)
        if pip install --user poetry; then
            poetry_installed=true
            log_success "Poetry installed via pip"
        else
            log_warn "pip install poetry failed, trying system package manager..."
            
            # Method 3: System package manager (if available)
            case "$OS" in
                linux)
                    if command_exists apt-get; then
                        if sudo apt-get install -y python3-poetry 2>/dev/null; then
                            poetry_installed=true
                            log_success "Poetry installed via apt"
                        fi
                    elif command_exists yum; then
                        if sudo yum install -y poetry 2>/dev/null; then
                            poetry_installed=true
                            log_success "Poetry installed via yum"
                        fi
                    elif command_exists pacman; then
                        if sudo pacman -S --noconfirm python-poetry 2>/dev/null; then
                            poetry_installed=true
                            log_success "Poetry installed via pacman"
                        fi
                    fi
                    ;;
                darwin)
                    if command_exists brew; then
                        if brew install poetry 2>/dev/null; then
                            poetry_installed=true
                            log_success "Poetry installed via Homebrew"
                        fi
                    fi
                    ;;
            esac
        fi
    fi
    
    if [ "$poetry_installed" = true ]; then
        # Add Poetry to PATH
        export PATH="$HOME/.local/bin:$PATH"
        
        # Add to shell config if not already there
        for shell_config in ~/.bashrc ~/.zshrc ~/.profile; do
            if [ -f "$shell_config" ] && ! grep -q "/.local/bin:" "$shell_config"; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_config"
                break
            fi
        done
        
        # Configure Poetry if available
        if command_exists poetry; then
            poetry config virtualenvs.in-project true 2>/dev/null || true
            log_success "Poetry configured successfully"
        fi
    else
        log_warn "Poetry installation failed with all methods"
        log_info "The project can still work with pip and virtual environments"
        log_info "You can install Poetry manually later from: https://python-poetry.org/docs/#installation"
    fi
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
            
            # Try official Docker installation script first
            if curl -fsSL --connect-timeout 10 https://get.docker.com | sh; then
                log_success "Docker installed via official script"
            else
                log_warn "Official Docker installer failed, trying package manager..."
                
                # Fallback to package manager
                if command_exists apt-get; then
                    sudo apt-get update
                    sudo apt-get install -y docker.io docker-compose
                    log_success "Docker installed via apt"
                elif command_exists yum; then
                    sudo yum install -y docker docker-compose
                    log_success "Docker installed via yum"
                elif command_exists pacman; then
                    sudo pacman -S --noconfirm docker docker-compose
                    log_success "Docker installed via pacman"
                else
                    log_error "Could not install Docker - no supported package manager found"
                    log_info "Please install Docker manually from: https://docs.docker.com/get-docker/"
                    return
                fi
            fi
            
            # Configure Docker
            if command_exists docker; then
                sudo usermod -aG docker $USER || log_warn "Could not add user to docker group"
                
                # Try to start Docker service
                if sudo systemctl start docker 2>/dev/null; then
                    sudo systemctl enable docker 2>/dev/null
                    log_success "Docker service started and enabled"
                elif sudo service docker start 2>/dev/null; then
                    log_success "Docker service started"
                else
                    log_warn "Could not start Docker service automatically"
                    log_info "You may need to start Docker manually: sudo systemctl start docker"
                fi
            fi
            ;;
        darwin)
            log_info "Installing Docker Desktop for macOS"
            if command_exists brew; then
                if brew install --cask docker; then
                    log_success "Docker Desktop installed via Homebrew"
                    log_info "Please start Docker Desktop from Applications"
                else
                    log_warn "Homebrew Docker installation failed"
                    log_info "Please install Docker Desktop manually from: https://www.docker.com/products/docker-desktop"
                fi
            else
                log_warn "Homebrew not available"
                log_info "Please install Docker Desktop manually from: https://www.docker.com/products/docker-desktop"
            fi
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
        
        # Try official installer with timeout
        if curl -fsSL --connect-timeout 10 https://ollama.ai/install.sh | sh; then
            log_success "Ollama installed successfully"
        else
            log_warn "Ollama installation failed"
            log_info "You can install Ollama manually later from: https://ollama.ai/download"
            log_info "The system will work without LLM features for now"
            return
        fi
    fi
    
    # Start Ollama service
    if ! pgrep -x "ollama" > /dev/null; then
        log_info "Starting Ollama service"
        if ollama serve &>/dev/null &; then
            sleep 5
            log_success "Ollama service started"
        else
            log_warn "Could not start Ollama service automatically"
            log_info "You can start it manually with: ollama serve"
        fi
    fi
    
    # Interactive model selection (only if Ollama is working)
    if command_exists ollama; then
        select_ollama_model
        log_success "Ollama installed and model ready"
    else
        log_warn "Ollama not available, skipping model installation"
    fi
}

# Interactive model selection for Ollama
select_ollama_model() {
    log_header "Ollama Model Selection"
    
    # Check if we can do interactive input (not piped from curl)
    if [[ ! -t 0 ]]; then
        log_info "Non-interactive mode detected (piped from curl)"
        log_info "Defaulting to phi3:mini for reliable installation"
        log_info "You can change models later with: ollama pull <model-name>"
        
        selected_model="phi3:mini"
        if ollama pull "$selected_model"; then
            log_success "Default model '$selected_model' downloaded successfully"
            OLLAMA_MODEL_NAME="$selected_model"
        else
            log_warn "Failed to download default model. You can install manually later."
        fi
        return
    fi
    
    echo -e "${CYAN}Available popular models for the Omnitide AI Suite:${NC}\n"
    
    # Define popular models with descriptions
    declare -A models
    models=(
        ["phi3:mini"]="Phi-3 Mini (3.8B) - Fast, efficient, great for coding and reasoning"
        ["llama3.1:8b"]="Llama 3.1 8B - Versatile, good balance of speed and capability"
        ["llama3.2:3b"]="Llama 3.2 3B - Lightweight, fast inference"
        ["codellama:7b"]="Code Llama 7B - Specialized for code generation and understanding"
        ["mistral:7b"]="Mistral 7B - Excellent instruction following and reasoning"
        ["gemma2:9b"]="Gemma 2 9B - Google's efficient model with strong performance"
        ["qwen2.5:7b"]="Qwen 2.5 7B - Strong multilingual and reasoning capabilities"
    )
    
    # Display options
    local i=1
    local model_keys=()
    for model in "${!models[@]}"; do
        echo -e "${YELLOW}$i)${NC} ${GREEN}$model${NC} - ${models[$model]}"
        model_keys+=("$model")
        ((i++))
    done
    
    echo -e "\n${YELLOW}8)${NC} ${CYAN}Custom model${NC} - Enter your own model name"
    echo -e "${YELLOW}9)${NC} ${BLUE}Skip model installation${NC} - Install later manually"
    
    # Get user selection with timeout and fallback
    echo ""
    local choice=""
    if read -t 30 -p "$(echo -e "${CYAN}Select a model [1-9] (30s timeout, defaults to 1):${NC} ")" choice; then
        echo ""
    else
        echo ""
        log_info "No input received, defaulting to option 1 (phi3:mini)"
        choice="1"
    fi
    
    local selected_model=""
    case $choice in
        [1-7])
            local index=$((choice-1))
            selected_model="${model_keys[$index]}"
            ;;
        8)
            echo ""
            local custom_model=""
            if read -t 30 -p "$(echo -e "${CYAN}Enter custom model name (e.g., llama3.1:8b):${NC} ")" custom_model; then
                if [[ -n "$custom_model" ]]; then
                    selected_model="$custom_model"
                else
                    log_warn "No model name provided, defaulting to phi3:mini"
                    selected_model="phi3:mini"
                fi
            else
                log_warn "Input timeout, defaulting to phi3:mini"
                selected_model="phi3:mini"
            fi
            ;;
        9)
            log_info "Skipping model installation - you can install later with: ollama pull <model-name>"
            return
            ;;
        ""|*)
            log_info "No selection or invalid input, defaulting to phi3:mini"
            selected_model="phi3:mini"
            ;;
    esac
    
    if [[ -n "$selected_model" ]]; then
        log_info "Pulling model: $selected_model (this may take a while depending on model size)"
        echo -e "${YELLOW}Note: First-time model downloads can be several GB. Please be patient...${NC}\n"
        
        if ollama pull "$selected_model"; then
            log_success "Model '$selected_model' downloaded successfully"
            
            # Update the global variable for use in config
            OLLAMA_MODEL_NAME="$selected_model"
            
            # Test the model
            log_info "Testing model..."
            if echo "Hello, respond with just 'Model working!' to confirm setup." | ollama run "$selected_model" --format json &>/dev/null; then
                log_success "Model test passed"
            else
                log_warn "Model test failed, but model should still work"
            fi
        else
            log_error "Failed to download model '$selected_model'"
            log_info "You can try again later with: ollama pull $selected_model"
        fi
    fi
}

# Install Tailscale
install_tailscale() {
    log_header "Installing Tailscale"
    
    if command_exists tailscale; then
        log_success "Tailscale already installed"
        return
    fi
    
    log_info "Installing Tailscale for secure networking"
    
    # Try official installer with timeout
    if curl -fsSL --connect-timeout 10 https://tailscale.com/install.sh | sh; then
        log_success "Tailscale installed successfully"
        log_info "To connect to Tailnet, run: sudo tailscale up"
    else
        log_warn "Tailscale installation failed"
        
        # Try package manager fallback
        case "$OS" in
            linux)
                if command_exists apt-get; then
                    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
                    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
                    sudo apt-get update && sudo apt-get install -y tailscale
                    log_success "Tailscale installed via apt"
                elif command_exists yum; then
                    sudo yum install -y yum-utils
                    sudo yum-config-manager --add-repo https://pkgs.tailscale.com/stable/rhel/9/tailscale.repo
                    sudo yum install -y tailscale
                    log_success "Tailscale installed via yum"
                else
                    log_warn "Could not install Tailscale automatically"
                    log_info "You can install it manually from: https://tailscale.com/download"
                fi
                ;;
            darwin)
                if command_exists brew; then
                    brew install tailscale
                    log_success "Tailscale installed via Homebrew"
                else
                    log_warn "Could not install Tailscale automatically"
                    log_info "You can install it manually from: https://tailscale.com/download"
                fi
                ;;
        esac
    fi
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
        if poetry install; then
            log_success "Poetry dependencies installed"
        elif poetry install --no-root; then
            log_success "Poetry dependencies installed (no-root mode)"
        else
            log_warn "Poetry installation failed, falling back to pip"
            pip install -r requirements.txt 2>/dev/null || pip install fastapi uvicorn scikit-learn pandas joblib dvc pydantic prometheus-client structlog rich pyyaml typer pytest pytest-cov ruff
        fi
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
# Global configuration
PYTHON_VERSION="3.10"
PROJECT_NAME="omnitide-ai-suite"
VENV_NAME=".venv"
OLLAMA_MODEL_NAME="phi3:mini"  # Default, can be changed during installation
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
    
    echo -e "${GREEN}🎉 Omnitide AI Suite installation finished!${NC}\n"
    
    # Show what was successfully installed
    echo -e "${CYAN}Installed Components:${NC}"
    local components=("python3:Python" "pip:Pip" "poetry:Poetry" "docker:Docker" "ollama:Ollama" "tailscale:Tailscale" "dvc:DVC")
    
    for component in "${components[@]}"; do
        local cmd="${component%:*}"
        local name="${component#*:}"
        if command_exists "$cmd"; then
            echo -e "  ✅ ${GREEN}$name${NC}"
        else
            echo -e "  ❌ ${YELLOW}$name (not installed)${NC}"
        fi
    done
    
    echo ""
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
    
    # Show any missing components and how to install them
    local missing_optional=()
    for component in "${components[@]}"; do
        local cmd="${component%:*}"
        local name="${component#*:}"
        if ! command_exists "$cmd" && [[ "$cmd" != "python3" && "$cmd" != "pip" ]]; then
            missing_optional+=("$name")
        fi
    done
    
    if [ ${#missing_optional[@]} -gt 0 ]; then
        echo -e "${YELLOW}Optional components not installed:${NC}"
        for component in "${missing_optional[@]}"; do
            case "$component" in
                "Poetry") echo -e "  • Install manually: ${CYAN}https://python-poetry.org/docs/#installation${NC}" ;;
                "Docker") echo -e "  • Install manually: ${CYAN}https://docs.docker.com/get-docker/${NC}" ;;
                "Ollama") echo -e "  • Install manually: ${CYAN}https://ollama.ai/download${NC}" ;;
                "Tailscale") echo -e "  • Install manually: ${CYAN}https://tailscale.com/download${NC}" ;;
                "DVC") echo -e "  • Install with: ${CYAN}pip install dvc${NC}" ;;
            esac
        done
        echo ""
    fi
    
    echo -e "${GREEN}Happy coding with Omnitide AI Suite! 🚀${NC}"
}

# Check network connectivity
check_network() {
    log_info "Checking network connectivity..."
    
    # Test basic connectivity
    if ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        log_success "Internet connectivity confirmed"
    else
        log_warn "Internet connectivity issues detected"
        log_info "Some installations may fail. Check your network connection."
    fi
    
    # Test HTTPS connectivity to key services
    local services=("https://install.python-poetry.org" "https://get.docker.com" "https://ollama.ai" "https://tailscale.com")
    local failed_services=()
    
    for service in "${services[@]}"; do
        if ! curl -fsSL --connect-timeout 5 --max-time 10 "$service" &>/dev/null; then
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        log_success "All installation services are reachable"
    else
        log_warn "Some services are unreachable:"
        for service in "${failed_services[@]}"; do
            log_warn "  - $service"
        done
        log_info "Installation will use fallback methods when possible"
    fi
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
    
    # Check network connectivity
    check_network
    
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
