#!/bin/bash
# install_interactive.sh - Interactive version of the Omnitide AI Suite installer
# Download and run for full interactive experience

# Download the main installer and run it directly (not piped)
TEMP_INSTALLER=$(mktemp)
curl -fsSL https://raw.githubusercontent.com/mrpongalfer/mlops/main/install.sh -o "$TEMP_INSTALLER"
chmod +x "$TEMP_INSTALLER"

echo "=========================================="
echo " Omnitide AI Suite - Interactive Installer"
echo "=========================================="
echo ""
echo "This will download and run the full interactive installer"
echo "where you can choose your preferred LLM model."
echo ""

# Run the installer directly (not piped)
exec "$TEMP_INSTALLER" "$@"
