#!/usr/bin/env bash
set -euo pipefail

ISO_NAME="OpenRUS-Cyberpunk-v1.0-x86_64.iso"
WORK_DIR="/tmp/openrus-build"
ISO_OUTPUT_DIR="/tmp/openrus-output"

mkdir -p "$WORK_DIR/chroot" "$WORK_DIR/iso/live" "$WORK_DIR/iso/isolinux" "$WORK_DIR/iso/boot/grub" "$ISO_OUTPUT_DIR"

echo "[1/6] Установка базовой системы..."
debootstrap --arch=amd64 bookworm "$WORK_DIR/chroot" http://deb.debian.org/debian/

echo "[2/6] Установка ядра, драйверов Wi-Fi Broadcom и графической среды..."
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
    firmware-iwlwifi \
    firmware-realtek \
    firmware-misc-nonfree \
    network-manager \
    wireless-tools \
    wpasupplicant \
    bluez \
    pulseaudio \
    pavucontrol \
    xserver-xorg \
    xinit \
    x11-xserver-utils \
    openbox \
    chromium \
    sudo \
    curl \
    git \
    python3

echo "openrus" > /etc/hostname

systemctl enable NetworkManager
systemctl enable bluetooth

# Создаем пользователя openrus без пароля
useradd -m -s /bin/bash -G sudo,audio,video,netdev openrus || true
passwd -d openrus || true
echo "openrus ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/openrus

# Автоматический вход без пароля при включении
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat << 'AUTOLOGIN' > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin openrus --noclear %I $TERM
AUTOLOGIN

# Автозапуск графической оболочки OpenRUS на весь экран
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

echo "[3/6] Копирование интерфейса OpenRUS..."
mkdir -p "$WORK_DIR/chroot/opt/openrus"
cp -r ../ui "$WORK_DIR/chroot/opt/openrus/" 2>/dev/null || true
cp -r ../assets "$WORK_DIR/chroot/opt/openrus/" 2>/dev/null || true
cp ../system/openrus-auto-drivers.sh "$WORK_DIR/chroot/usr/local/bin/openrus-auto-drivers" 2>/dev/null || true
cp ../system/openrus-updater.py "$WORK_DIR/chroot/usr/local/bin/openrus-updater" 2>/dev/null || true
chmod +x "$WORK_DIR/chroot/usr/local/bin/openrus-auto-drivers" 2>/dev/null || true
chmod +x "$WORK_DIR/chroot/usr/local/bin/openrus-updater" 2>/dev/null || true

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

echo "[6/6] Создание Hybrid ISO для Rufus..."
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

echo "Сборка завершена: $ISO_OUTPUT_DIR/$ISO_NAME"
