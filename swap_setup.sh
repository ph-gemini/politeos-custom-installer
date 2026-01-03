#!/bin/bash

# 1. Create 6GB Disk Swap File
echo "Creating 6GB swap file..."
sudo swapoff -a
sudo dd if=/dev/zero of=/swapfile bs=1M count=6144
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Add to fstab if not exists
if ! grep -q "/swapfile" /etc/fstab; then
    echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
fi

# 2. Configure Zswap (30% Max Pool, LZ4 Compressor)
echo "Configuring Zswap parameters..."

# Set immediate parameters
sudo bash -c "echo 1 > /sys/module/zswap/parameters/enabled"
sudo bash -c "echo lz4 > /sys/module/zswap/parameters/compressor"
sudo bash -c "echo 30 > /sys/module/zswap/parameters/max_pool_percent"
sudo bash -c "echo zsmalloc > /sys/module/zswap/parameters/zpool"

# 3. Apply to GRUB to make it permanent
echo "Updating GRUB boot parameters..."
GRUB_PARAM="zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=30 zswap.zpool=zsmalloc"

if grep -q "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub; then
    # Add parameters inside the quotes of GRUB_CMDLINE_LINUX_DEFAULT
    sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$GRUB_PARAM /" /etc/default/grub
    sudo update-grub
fi

echo "Zswap and Disk Swap setup completed."
