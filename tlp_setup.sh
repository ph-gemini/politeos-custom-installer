#!/bin/bash

# 1. Install TLP
echo "Installing TLP and its dependencies..."
sudo apt update
sudo apt install -y tlp tlp-rdw

# 2. Sync Custom TLP Config from Repo
# Assuming the file is already downloaded via your git sync script
REPO_TLP_CONFIG="/tmp/my_configs/tlp/tlp.conf"
SYSTEM_TLP_CONFIG="/etc/tlp.conf"

if [ -f "$REPO_TLP_CONFIG" ]; then
    echo "Applying custom tlp.conf from repository..."
    # Backup original config just in case
    sudo mv "$SYSTEM_TLP_CONFIG" "$SYSTEM_TLP_CONFIG.bak"
    # Copy your custom config
    sudo cp "$REPO_TLP_CONFIG" "$SYSTEM_TLP_CONFIG"
else
    echo "Error: Custom tlp.conf not found in $REPO_TLP_CONFIG"
fi

# 3. Enable and Start TLP Service
echo "Enabling TLP service..."
sudo systemctl enable tlp
sudo tlp start

echo "TLP configuration completed."
