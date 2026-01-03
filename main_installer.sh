#!/bin/bash

# Configuration
OS_NAME="PoliteOS"
REPO_URL="https://github.com/ph-gemini/politeos-custom-installer"
TARGET_USER="liveuser"

# 1. Drive Selector Window
# This lists only disks (not partitions) and asks the user to pick one
TARGET_DRIVE=$(lsblk -dno NAME,SIZE,MODEL | zenity --list \
    --title="Select Installation Disk" \
    --text="Please choose the disk where you want to install $OS_NAME:" \
    --column="Drive" --column="Size" --column="Model" \
    --width=500 --height=300 | awk '{print "/dev/"$1}')

# If user cancels, exit script
if [ -z "$TARGET_DRIVE" ]; then
    zenity --error --text="No disk selected. Installation cancelled."
    exit 1
fi

# Confirmation Box
zenity --question --text="Are you sure? All data on $TARGET_DRIVE will be deleted!" --width=300
if [ $? != 0 ]; then exit 1; fi

# 2. Partitioning and Installation Process
(
echo "10" ; echo "# Partitioning disk ($TARGET_DRIVE)..."
# Create GPT Partition Table
# 1st Partition: 8MB BIOS-Grub, 2nd Partition: Root (/)
sudo parted -s $TARGET_DRIVE mklabel gpt
sudo parted -s $TARGET_DRIVE mkpart primary 1MiB 9MiB
sudo parted -s $TARGET_DRIVE set 1 bios_grub on
sudo parted -s $TARGET_DRIVE mkpart primary 9MiB 100%

echo "30" ; echo "# Formatting Partition..."
# We use ${TARGET_DRIVE}2 because it's the second partition (Root)
# Note: For NVMe drives, it might be p2. This logic handles basic /dev/sdX.
ROOT_PART="${TARGET_DRIVE}2"
if [[ $TARGET_DRIVE == *"nvme"* ]]; then ROOT_PART="${TARGET_DRIVE}p2"; fi

sudo mkfs.ext4 -F $ROOT_PART
sudo mount $ROOT_PART /mnt

echo "50" ; echo "# Copying system files (Live to Disk)..."
sudo rsync -aAXv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / /mnt

echo "70" ; echo "# Installing Optimized XanMod Kernel..."
sudo cp installer.sh /mnt/tmp/
sudo chroot /mnt /bin/bash /tmp/installer.sh

echo "85" ; echo "# Configuring Zswap and 6GB Swap..."
sudo cp swap_setup.sh /mnt/tmp/
sudo chroot /mnt /bin/bash /tmp/swap_setup.sh

echo "90" ; echo "# Syncing PoliteOS Custom Configs and TLP..."
sudo cp config_sync.sh /mnt/tmp/
sudo cp tlp_setup.sh /mnt/tmp/
sudo chroot /mnt /bin/bash /tmp/config_sync.sh
sudo chroot /mnt /bin/bash /tmp/tlp_setup.sh

echo "95" ; echo "# Finalizing Bootloader..."
sudo grub-install --target=i386-pc $TARGET_DRIVE
sudo chroot /mnt update-grub

echo "100" ; echo "# Done!"
) | zenity --progress --title="$OS_NAME Installation" --percentage=0 --auto-close

zenity --info --text="PoliteOS has been installed successfully. Please remove the Live USB and Restart."
