#!/bin/bash
# intelligent_setup.sh
set -e

echo "🚀 Starting Intelligent Omnitide AI Suite Setup..."

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install with different package managers
install_python_packages() {
    local packages="$1"
    
    if command_exists poetry; then
        echo "📦 Installing with Poetry..."
        poetry install --no-dev 2>/dev/null || {
            echo "⚠️  Poetry install failed, trying pip..."
            poetry run pip install $packages
        }
    elif command_exists pip3; then
        echo "📦 Installing with pip3..."
        pip3 install $packages
    elif command_exists pip; then
        echo "📦 Installing with pip..."
        pip install $packages
    else
        echo "❌ No Python package manager found!"
        exit 1
    fi
}

# Essential packages that we need
ESSENTIAL_PACKAGES="fastapi uvicorn pandas scikit-learn pydantic"
OPTIONAL_PACKAGES="structlog typer rich prometheus-client joblib pyyaml"

# Check Python version
python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
echo "🐍 Python version: $python_version"

# Install essential packages
echo "📦 Installing essential packages..."
install_python_packages "$ESSENTIAL_PACKAGES"

# Try to install optional packages
echo "📦 Installing optional packages (failures are OK)..."
for package in $OPTIONAL_PACKAGES; do
    install_python_packages "$package" || echo "⚠️  Could not install $package, continuing..."
done

# Create sample data if none exists
echo "📊 Setting up sample data..."
python3 -c "
import sys
sys.path.insert(0, 'src')
try:
    from intelligent_config import ensure_environment
    ensure_environment()
    print('✅ Intelligent configuration setup complete')
except Exception as e:
    print(f'⚠️  Could not run intelligent setup: {e}')
    # Create basic sample data
    import os
    os.makedirs('data/raw', exist_ok=True)
    with open('data/raw/data.csv', 'w') as f:
        f.write('feature1,feature2,feature3,target\n')
        for i in range(100):
            f.write(f'{i%10},{(i*2)%10},{"A" if i%2 else "B"},{i%2}\n')
    print('✅ Basic sample data created')
"

# Make directories
echo "📁 Creating directories..."
mkdir -p data/raw models reports src

# Make scripts executable
chmod +x *.sh 2>/dev/null || true

# Check for optional tools
echo "🔍 Checking for optional tools..."

if command_exists ollama; then
    echo "✅ Ollama found"
    ollama pull phi3:3.8b-mini-instruct-4k-q4_0 || echo "⚠️  Could not pull Ollama model"
else
    echo "⚠️  Ollama not found - LLM features will be limited"
fi

if command_exists tailscale; then
    echo "✅ Tailscale found"
else
    echo "⚠️  Tailscale not found - networking features will be limited"
fi

if command_exists docker; then
    echo "✅ Docker found"
else
    echo "⚠️  Docker not found - containerization features will be limited"
fi

if command_exists dvc; then
    echo "✅ DVC found"
    # Initialize DVC if not already done
    dvc init --no-scm 2>/dev/null || echo "📝 DVC already initialized"
else
    echo "⚠️  DVC not found - model versioning will be limited"
fi

# Test the application
echo "🧪 Testing the application..."
python3 -c "
import sys
sys.path.insert(0, 'src')
try:
    from intelligent_config import intelligent_config
    config = intelligent_config.get_config()
    print('✅ Configuration loaded successfully')
    print(f'📊 Available dependencies: {sum(config.get(\"dependencies\", {}).get(\"core\", {}).values())} core modules')
    print(f'🚀 API will run on port: {config.get(\"api\", {}).get(\"port\", 8000)}')
except Exception as e:
    print(f'⚠️  Configuration test failed: {e}')
"

echo ""
echo "🎉 Intelligent setup complete!"
echo ""
echo "🚀 To start the application:"
echo "   python3 main_intelligent.py"
echo ""
echo "🧪 To test the API:"
echo "   curl http://localhost:8000/v1/health"
echo ""
echo "📖 Available endpoints:"
echo "   GET  /v1/health  - Health check with dependency status"
echo "   GET  /v1/ready   - Readiness check"
echo "   POST /v1/predict - Make predictions"
echo "   GET  /v1/info    - System information"
echo "   GET  /metrics    - Prometheus metrics"
echo ""
