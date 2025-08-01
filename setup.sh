#!/bin/bash
# setup.sh
set -e
echo "--- Activating Edict of Perpetual Effortless Manifestation (EPEM) ---"
if ! command -v x &> /dev/null; then
    eval "$(curl -fsSL https://get.x-cmd.com)"
fi
poetry config virtualenvs.in-project true
x env install python@3.10
x env use python@3.10
x env install dvc
if ! command -v poetry &> /dev/null; then
    x env install poetry
fi
poetry install
echo "Installing Ollama for local LLM orchestration..."
curl -fsSL https://ollama.ai/install.sh | sh
OLLAMA_MODEL="phi3:3.8b-mini-instruct-4k-q4_0"
echo "Pulling Ollama model: $OLLAMA_MODEL"
ollama pull "$OLLAMA_MODEL"
echo "Installing Tailscale to join the Omnitide Tailnet..."
curl -fsSL https://tailscale.com/install.sh | sh
dvc init --no-scm || true
dvc pull
echo "--- Setup complete. ---"
