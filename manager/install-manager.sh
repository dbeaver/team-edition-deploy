#!/bin/bash

set -e

INSTALL_DIR="$HOME/bin"
CURRENT_DIR=$(pwd)
mkdir -p "$INSTALL_DIR"

# Determine the actual base directory and compose directory
BASE_DIR=$(realpath "$CURRENT_DIR/..")
CBTE_DIR=$(realpath "$CURRENT_DIR/../compose/cbte")

# Copy the script to install directory
cp "$CURRENT_DIR/dbeaver-te" "$INSTALL_DIR/dbeaver-te"
chmod +x "$INSTALL_DIR/dbeaver-te"

# Replace the hardcoded paths with actual paths
sed -i "s|^TEAM_EDITION_BASE_DIR=.*|TEAM_EDITION_BASE_DIR=\"$BASE_DIR\"|g" "$INSTALL_DIR/dbeaver-te"
sed -i "s|^TEAM_EDITION_COMPOSE_DIR=.*|TEAM_EDITION_COMPOSE_DIR=\"$CBTE_DIR\"|g" "$INSTALL_DIR/dbeaver-te"

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> ~/.bashrc
    source ~/.bashrc
fi

echo "DBeaver Team Edition manager installed successfully!"
echo "Base directory: $BASE_DIR"
echo "Compose directory: $CBTE_DIR" 