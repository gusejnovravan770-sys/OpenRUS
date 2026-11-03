#!/usr/bin/env bash
# ==============================================================================
# OpenRUS OS - Hybrid ISO Builder (Rufus MBR + DD Image Mode Ready)
# Builds a bootable x86_64 Live ISO containing:
# - Cyberpunk Bear Desktop Interface (Vertical Dock, OpenMarket, Browser, Tray)
# - Real Wi-Fi, Bluetooth, NVMe, CPU, GPU automatic driver stack
# - In-place GitHub Update Center
# - Branded Calamares Installer with Cyberpunk theme
# ==============================================================================

set -euo pipefail

ISO_NAME="OpenRUS-Cyberpunk-v1.0-x86_64.iso"
WORK_DIR="/tmp/openrus-build"
ISO_OUTPUT_DIR="/tmp/openrus-output"

echo "=========================================================="
echo "          Starting OpenRUS Hybrid ISO Build               "
echo "=========================================================="

# 1. Check prerequisites
for cmd in xorriso isohybrid debootstrap squashfs-tools; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[ERROR] Missing build tool: $cmd"
        echo "Run: sudo apt-get update && sudo apt-get install -y debootstrap squashfs-tools xorriso syslinux-utils"
        exit 1
    fi
done

mkdir -p "$WORK_DIR/chroot" "$WORK_DIR/iso/live" "$WORK_DIR/iso/isolinux" "$WORK_DIR/iso/boot/grub" "$ISO_OUTPUT_DIR"

echo "[1/6] Bootstrapping Base 64-bit Linux System..."
debootstrap --arch=amd64 bookworm "$WORK_DIR/chroot" http://deb.debian.org/debian/

echo "[2/6] Configuring Kernel, Drivers & Network Stacks..."
cat << 'EOF' > "$WORK_DIR/chroot/tmp/setup-chroot.sh"
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# Repositories including non-free-firmware for maximum Wi-Fi/GPU compatibility
cat << 'REPOS' > /etc/apt/sources.list
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
REPOS

apt-get update
apt-get install -y --no-install-recommends \
    linux-image-amd64 \
    live-boot \
    systemd-sysv \
    firmware-linux \
    firmware-iwlwifi \
    firmware-realtek \
    firmware-misc-nonfree \
    network-manager \
    wireless-tools \
    wpasupplicant \
    bluez \
    pulseaudio \
    pavucontrol \
    xorg \
    chromium \
    python3 \
    python3-pip \
    curl \
    git \
    calamares \
    calamares-settings-debian

# Set system hostname
echo "openrus" > /etc/hostname

# Enable hardware services
systemctl enable NetworkManager
systemctl enable bluetooth
EOF

chmod +x "$WORK_DIR/chroot/tmp/setup-chroot.sh"
chroot "$WORK_DIR/chroot" /tmp/setup-chroot.sh
rm "$WORK_DIR/chroot/tmp/setup-chroot.sh"

echo "[3/6] Installing OpenRUS Desktop Environment & Calamares Theme..."
# Copy OpenRUS assets, UI, auto-drivers and updater
mkdir -p "$WORK_DIR/chroot/opt/openrus"
cp -r ../ui "$WORK_DIR/chroot/opt/openrus/"
cp -r ../assets "$WORK_DIR/chroot/opt/openrus/"
cp ../system/openrus-auto-drivers.sh "$WORK_DIR/chroot/usr/local/bin/openrus-auto-drivers"
cp ../system/openrus-updater.py "$WORK_DIR/chroot/usr/local/bin/openrus-updater"
chmod +x "$WORK_DIR/chroot/usr/local/bin/openrus-auto-drivers"
chmod +x "$WORK_DIR/chroot/usr/local/bin/openrus-updater"

# Copy Calamares Cyberpunk Theme
mkdir -p "$WORK_DIR/chroot/etc/calamares/branding/openrus"
cp -r ../installer/calamares/branding/openrus/* "$WORK_DIR/chroot/etc/calamares/branding/openrus/"

echo "[4/6] Creating SquashFS compressed root filesystem..."
mksquashfs "$WORK_DIR/chroot" "$WORK_DIR/iso/live/filesystem.squashfs" -comp xz -e boot

# Copy Kernel & Initrd to live directory
cp "$WORK_DIR/chroot/boot"/vmlinuz-* "$WORK_DIR/iso/live/vmlinuz"
cp "$WORK_DIR/chroot/boot"/initrd.img-* "$WORK_DIR/iso/live/initrd"

echo "[5/6] Configuring ISOLINUX & GRUB Bootloader for MBR..."
cat << 'EOF' > "$WORK_DIR/iso/isolinux/isolinux.cfg"
UI vesamenu.c32
PROMPT 0
TIMEOUT 50
DEFAULT openrus

MENU TITLE OpenRUS OS - Cyberpunk Edition (MBR Mode)

LABEL openrus
  MENU LABEL OpenRUS Live (Run without installation)
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd boot=live quiet splash components

LABEL install
  MENU LABEL Install OpenRUS (Calamares Installer)
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd boot=live quiet splash components calamares
EOF

echo "[6/6] Packing Hybrid ISO & Applying isohybrid (for Rufus DD Mode)..."
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "OPENRUS_OS" \
    -eltorito-boot isolinux/isolinux.bin \
    -eltorito-catalog isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -output "$ISO_OUTPUT_DIR/$ISO_NAME" \
    "$WORK_DIR/iso"

# Enable Rufus DD and MBR compatibility
isohybrid "$ISO_OUTPUT_DIR/$ISO_NAME"

echo "=========================================================="
echo " [SUCCESS] ISO image created successfully!"
echo " File: $ISO_OUTPUT_DIR/$ISO_NAME"
echo " Write to USB with Rufus:"
echo " - Partition Scheme: MBR"
echo " - Write Mode: DD Image Mode (or ISO Image Mode)"
echo "=========================================================="
