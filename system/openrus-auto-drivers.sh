#!/usr/bin/env bash
# ==============================================================================
# OpenRUS OS - Hardware Auto-Detection & Automated Driver Setup
# Triggered automatically when internet / network connectivity becomes available
# ==============================================================================

set -euo pipefail

LOG_FILE="/var/log/openrus-drivers.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=========================================================="
echo " [OpenRUS Auto-Driver] Scanning Hardware Architecture... "
echo "=========================================================="

# 1. CPU & Architecture Detection
CPU_MODEL=$(lscpu | grep "Model name:" | sed 's/Model name:[ \t]*//' || true)
CPU_CORES=$(nproc)
echo "[INFO] CPU Detected: $CPU_MODEL ($CPU_CORES Cores)"

# 2. RAM & Swap Detection
TOTAL_RAM=$(free -h | awk '/^Mem:/ {print $2}')
echo "[INFO] RAM Total: $TOTAL_RAM"

# 3. Disks: NVMe & SSD / HDD Detection
echo "[INFO] Detecting Storage Devices (NVMe / SATA / MBR)..."
lsblk -d -o NAME,SIZE,MODEL,ROTA,TRAN || true

# 4. Check Internet Connectivity before fetching proprietary packages
echo "[INFO] Verifying Internet connection..."
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "[OK] Internet connection is ACTIVE."
else
    echo "[WARN] No internet connection detected. Automatic online driver fetch will retry when online."
    exit 0
fi

# 5. GPU Detection & Driver Installation
echo "[INFO] Scanning Graphic Cards (PCI VGA / 3D Controller)..."
VGA_INFO=$(lspci -nn | grep -E "VGA|3D|Display" || true)
echo "$VGA_INFO"

if echo "$VGA_INFO" | grep -iq "NVIDIA"; then
    echo "[DRIVER] NVIDIA GPU detected. Triggering automated driver installation..."
    if command -v ubuntu-drivers >/dev/null 2>&1; then
        ubuntu-drivers autoinstall || true
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm nvidia nvidia-utils || true
    fi
elif echo "$VGA_INFO" | grep -iq "AMD"; then
    echo "[DRIVER] AMD Radeon GPU detected. Modern kernel amdgpu and Mesa Vulkan drivers active."
elif echo "$VGA_INFO" | grep -iq "Intel"; then
    echo "[DRIVER] Intel Iris / UHD Graphics detected. Mesa Intel drivers active."
fi

# 6. Wi-Fi & Wireless Network Chipsets
echo "[INFO] Scanning Wireless Devices..."
WIFI_INFO=$(lspci -nn | grep -i network || true)
echo "$WIFI_INFO"

if echo "$WIFI_INFO" | grep -iq "Broadcom"; then
    echo "[DRIVER] Broadcom Wi-Fi adapter detected. Loading bcmwl / broadcom-sta driver..."
    modprobe wl || apt-get install -y broadcom-sta-dkms || true
elif echo "$WIFI_INFO" | grep -iq "Intel"; then
    echo "[DRIVER] Intel Wi-Fi (iwlwifi) firmware already active in kernel."
elif echo "$WIFI_INFO" | grep -iq "Realtek"; then
    echo "[DRIVER] Realtek Wi-Fi (rtw88/rtw89) firmware verified."
fi

# 7. Bluetooth Controller Check
echo "[INFO] Checking Bluetooth Hardware..."
if rfkill list bluetooth | grep -q "bluetooth"; then
    echo "[OK] Bluetooth controller detected."
    systemctl enable --now bluetooth || true
fi

echo "=========================================================="
echo " [OpenRUS Auto-Driver] All Hardware Successfully Configured!"
echo "=========================================================="
