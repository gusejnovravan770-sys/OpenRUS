#!/usr/bin/env bash
set -euo pipefail

ISO_NAME="OpenRUS-Cyberpunk-v1.0-x86_64.iso"
WORK_DIR="/tmp/openrus-build"
ISO_OUTPUT_DIR="/tmp/openrus-output"

mkdir -p "$WORK_DIR/chroot" "$WORK_DIR/iso/live" "$WORK_DIR/iso/isolinux" "$WORK_DIR/iso/boot/grub" "$ISO_OUTPUT_DIR"

echo "[1/6] Установка базовой системы..."
debootstrap --arch=amd64 bookworm "$WORK_DIR/chroot" http://deb.debian.org/debian/

echo "[2/6] Установка универсальных драйверов (Broadcom, Intel, Realtek, Atheros)..."
cat << 'EOF' > "$WORK_DIR/chroot/tmp/setup-chroot.sh"
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

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
    firmware-brcm80211 \
    firmware-realtek \
    firmware-iwlwifi \
    firmware-atheros \
    firmware-misc-nonfree \
    network-manager \
    wireless-tools \
    wpasupplicant \
    rfkill \
    bluez \
    pulseaudio \
    pavucontrol \
    xserver-xorg \
    xinit \
    x11-xserver-utils \
    openbox \
    chromium \
    parted \
    rsync \
    grub-pc \
    sudo \
    curl \
    git \
    python3

echo "openrus" > /etc/hostname
echo "127.0.0.1 localhost openrus" > /etc/hosts

systemctl enable NetworkManager
systemctl enable bluetooth

useradd -m -s /bin/bash -G sudo,audio,video,netdev openrus || true
passwd -d openrus || true
echo "openrus ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/openrus

mkdir -p /etc/systemd/system/getty@tty1.service.d
cat << 'AUTOLOGIN' > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin openrus --noclear %I $TERM
AUTOLOGIN

# Служба бэкенда для реального Wi-Fi и установщика
cat << 'SERVICE' > /etc/systemd/system/openrus-backend.service
[Unit]
Description=OpenRUS Desktop System Daemon
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /opt/openrus/system/openrus-backend.py
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
SERVICE
systemctl enable openrus-backend.service

# Автозапуск Wi-Fi чипов Broadcom/Intel/Realtek без терминала
cat << 'AUTO_WIFI' > /usr/local/bin/openrus-wifi-autostart
#!/bin/bash
rfkill unblock all || true
if lspci -nn | grep -iq "14e4:"; then
    modprobe brcmsmac || modprobe b43 allhwsupport=1 || true
fi
systemctl restart NetworkManager || true
AUTO_WIFI
chmod +x /usr/local/bin/openrus-wifi-autostart

cat << 'WIFI_SERVICE' > /etc/systemd/system/openrus-wifi.service
[Unit]
Description=OpenRUS Wi-Fi Auto-Initializer
After=NetworkManager.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/openrus-wifi-autostart

[Install]
WantedBy=multi-user.target
WIFI_SERVICE
systemctl enable openrus-wifi.service

cat << 'PROFILE' > /home/openrus/.bash_profile
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
PROFILE
chown openrus:openrus /home/openrus/.bash_profile

cat << 'XINIT' > /home/openrus/.xinitrc
#!/bin/bash
xset s off -dpms &
xsetroot -solid "#080b11" -cursor_name left_ptr &
openbox &
chromium --no-first-run --no-default-browser-check --disable-translate --start-fullscreen --app="file:///opt/openrus/ui/index.html" &
wait
XINIT
chmod +x /home/openrus/.xinitrc
chown openrus:openrus /home/openrus/.xinitrc
EOF

chmod +x "$WORK_DIR/chroot/tmp/setup-chroot.sh"
chroot "$WORK_DIR/chroot" /tmp/setup-chroot.sh
rm "$WORK_DIR/chroot/tmp/setup-chroot.sh"

echo "[3/6] Копирование интерфейса и системных служб OpenRUS..."
mkdir -p "$WORK_DIR/chroot/opt/openrus"
cp -r ../ui "$WORK_DIR/chroot/opt/openrus/" 2>/dev/null || true
cp -r ../assets "$WORK_DIR/chroot/opt/openrus/" 2>/dev/null || true
cp -r ../system "$WORK_DIR/chroot/opt/openrus/" 2>/dev/null || true
chmod +x "$WORK_DIR/chroot/opt/openrus/system"/*.py 2>/dev/null || true

echo "[4/6] Упаковка SquashFS..."
mksquashfs "$WORK_DIR/chroot" "$WORK_DIR/iso/live/filesystem.squashfs" -comp xz -e boot

cp "$WORK_DIR/chroot/boot"/vmlinuz-* "$WORK_DIR/iso/live/vmlinuz"
cp "$WORK_DIR/chroot/boot"/initrd.img-* "$WORK_DIR/iso/live/initrd"

echo "[5/6] Настройка загрузчика ISOLINUX..."
cp /usr/lib/ISOLINUX/isolinux.bin "$WORK_DIR/iso/isolinux/" 2>/dev/null || cp /usr/lib/syslinux/isolinux.bin "$WORK_DIR/iso/isolinux/" 2>/dev/null || true
cp /usr/lib/syslinux/modules/bios/*.c32 "$WORK_DIR/iso/isolinux/" 2>/dev/null || cp /usr/lib/syslinux/bios/*.c32 "$WORK_DIR/iso/isolinux/" 2>/dev/null || true

cat << 'EOF' > "$WORK_DIR/iso/isolinux/isolinux.cfg"
UI vesamenu.c32
PROMPT 0
TIMEOUT 30
DEFAULT openrus

MENU TITLE OpenRUS OS - Cyberpunk Edition (MBR Mode)

LABEL openrus
  MENU LABEL Start OpenRUS OS (Cyberpunk GUI)
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd boot=live quiet splash components
EOF

echo "[6/6] Создание Hybrid ISO для Rufus (MBR + DD)..."
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "OPENRUS_OS" \
    -eltorito-boot isolinux/isolinux.bin \
    -eltorito-catalog isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -output "$ISO_OUTPUT_DIR/$ISO_NAME" \
    "$WORK_DIR/iso"

isohybrid "$ISO_OUTPUT_DIR/$ISO_NAME" 2>/dev/null || true
echo "Сборка готова: $ISO_OUTPUT_DIR/$ISO_NAME"
