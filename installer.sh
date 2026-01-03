#!/bin/bash

# 1. Setup XanMod Repository
wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/xanmod-archive-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/xanmod-release.list

sudo apt update

# 2. Detect CPU Architecture Level
CPU_V=$(/lib64/ld-linux-x86-64.so.2 --help | grep -E "v2|v3|v4" | tail -n 1 | awk '{print $1}')

echo "Detected CPU Architecture: $CPU_V"

# 3. Install Kernel based on CPU Level
case $CPU_V in
    "v4")
        echo "CPU v4 detected. Skipping XanMod installation as per instructions."
        ;;
    "v3")
        echo "Installing XanMod v3..."
        sudo apt install -y linux-xanmod-x64v3
        ;;
    "v2")
        echo "Installing XanMod Edge v2..."
        sudo apt install -y linux-xanmod-edge-x64v2
        ;;
    *)
        echo "Falling back to XanMod LTS v1..."
        sudo apt install -y linux-xanmod-lts-x64v1
        ;;
esac

# 4. Install Development Tools and Dependencies
sudo apt install -y --no-install-recommends dkms libdw-dev clang lld llvm
