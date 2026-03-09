#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
INSTALL_DIR="$HOME/bin"

BASE_DIR=$(realpath "$SCRIPT_DIR/..")
CBTE_DIR=$(realpath "$SCRIPT_DIR/../compose/cbte")

mkdir -p "$INSTALL_DIR"

cp "$SCRIPT_DIR/dbeaver-te" "$INSTALL_DIR/dbeaver-te"
chmod +x "$INSTALL_DIR/dbeaver-te"

sed -i "s|^TEAM_EDITION_BASE_DIR=.*|TEAM_EDITION_BASE_DIR=\"$BASE_DIR\"|g" "$INSTALL_DIR/dbeaver-te"
sed -i "s|^TEAM_EDITION_COMPOSE_DIR=.*|TEAM_EDITION_COMPOSE_DIR=\"$CBTE_DIR\"|g" "$INSTALL_DIR/dbeaver-te"

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> ~/.bashrc
    source ~/.bashrc
fi

echo "DBeaver Team Edition manager installed successfully!"
echo "Base directory: $BASE_DIR"
echo "Compose directory: $CBTE_DIR" 