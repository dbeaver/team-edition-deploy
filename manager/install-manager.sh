#!/bin/bash

set -e

INSTALL_DIR="$HOME/bin"
CURRENT_DIR=$(pwd)
mkdir -p "$INSTALL_DIR"

ln -sf "$CURRENT_DIR/dbeaver-te" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/dbeaver-te"

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> ~/.bashrc
    source ~/.bashrc
fi

CBTE_DIR=$(realpath "$CURRENT_DIR/../compose/cbte")
sed -i "s|/opt/dbeaver-team-server/team-edition-deploy/compose/cbte/|$CBTE_DIR/|g" "$INSTALL_DIR/dbeaver-te"
