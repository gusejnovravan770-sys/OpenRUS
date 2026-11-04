#!/usr/bin/env python3
import os
import sys
import json
import time
import subprocess
import threading
import urllib.request
from http.server import HTTPServer, BaseHTTPRequestHandler

REPO_URL = "https://api.github.com/repos/gusejnovravan770-sys/OpenRUS"
INSTALLED_FLAG = "/etc/openrus-installed"
INSTALL_PROGRESS = {"status": "idle", "percent": 0, "message": "Ожидание запуска"}

def get_installed_status():
    return os.path.exists(INSTALLED_FLAG)

def get_real_wifi_list():
    networks = []
    try:
        subprocess.run(["nmcli", "dev", "wifi", "rescan"], capture_output=True, timeout=5)
    except Exception:
        pass
    try:
        res = subprocess.run(["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"], capture_output=True, text=True, timeout=8)
        for line in res.stdout.strip().split("\n"):
            if not line: continue
            parts = line.split(":")
            if len(parts) >= 4:
                ssid = parts[1].strip()
                if ssid and ssid != "--":
                    networks.append({
                        "ssid": ssid,
                        "signal": int(parts[2]) if parts[2].isdigit() else 50,
                        "security": parts[3] or "Open",
                        "connected": (parts[0] == "*")
                    })
    except Exception:
        networks = []
    networks.sort(key=lambda x: (x["connected"], x["signal"]), reverse=True)
    return networks

def connect_real_wifi(ssid, password):
    cmd = ["nmcli", "dev", "wifi", "connect", ssid]
    if password: cmd.extend(["password", password])
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=20)
        return {"success": (res.returncode == 0), "message": res.stdout.strip() or res.stderr.strip()}
    except Exception as e:
        return {"success": False, "message": str(e)}

def run_installation_worker(target_dev):
    global INSTALL_PROGRESS
    try:
        INSTALL_PROGRESS = {"status": "running", "percent": 15, "message": f"Разметка диска {target_dev} (MBR)..."}
        subprocess.run(["parted", target_dev, "--script", "mklabel", "msdos", "mkpart", "primary", "ext4", "1MiB", "100%", "set", "1", "boot", "on"], check=True)
        part = f"{target_dev}1" if "nvme" not in target_dev else f"{target_dev}p1"
        
        INSTALL_PROGRESS = {"status": "running", "percent": 30, "message": f"Форматирование {part} в ext4..."}
        subprocess.run(["mkfs.ext4", "-F", part], check=True)
        
        INSTALL_PROGRESS = {"status": "running", "percent": 50, "message": "Копирование OpenRUS на жесткий диск..."}
        os.makedirs("/mnt/target", exist_ok=True)
        subprocess.run(["mount", part, "/mnt/target"], check=True)
        cmd = ["rsync", "-aAX", "--exclude=/dev/*", "--exclude=/proc/*", "--exclude=/sys/*", "--exclude=/tmp/*", "--exclude=/run/*", "--exclude=/mnt/*", "--exclude=/media/*", "--exclude=/lost+found", "/", "/mnt/target/"]
        subprocess.run(cmd, check=True)
        
        INSTALL_PROGRESS = {"status": "running", "percent": 85, "message": "Настройка загрузчика GRUB..."}
        with open("/mnt/target/etc/fstab", "w") as f:
            f.write(f"{part} / ext4 defaults,noatime 0 1\n")
        with open("/mnt/target/etc/openrus-installed", "w") as f:
            f.write("installed=true\n")
            
        subprocess.run(["grub-install", "--target=i386-pc", "--boot-directory=/mnt/target/boot", target_dev], check=True)
        subprocess.run(["chroot", "/mnt/target", "update-grub"], check=True)
        INSTALL_PROGRESS = {"status": "completed", "percent": 100, "message": "Установка завершена! Можете вытащить флешку."}
    except Exception as e:
        INSTALL_PROGRESS = {"status": "error", "percent": 0, "message": f"Ошибка: {str(e)}"}

class Handler(BaseHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        super().end_headers()
    def do_OPTIONS(self):
        self.send_response(200); self.end_headers()
    def do_GET(self):
        if self.path == "/api/wifi/list": self.send_json(get_real_wifi_list())
        elif self.path == "/api/installer/status": self.send_json(INSTALL_PROGRESS)
        elif self.path == "/api/installer/is_installed": self.send_json({"is_installed": get_installed_status()})
        else: self.send_response(404); self.end_headers()
    def do_POST(self):
        l = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(l).decode()) if l > 0 else {}
        if self.path == "/api/wifi/connect":
            self.send_json(connect_real_wifi(body.get("ssid"), body.get("password")))
        elif self.path == "/api/installer/start":
            threading.Thread(target=run_installation_worker, args=(body.get("device", "/dev/sda"),), daemon=True).start()
            self.send_json({"started": True})
        elif self.path == "/api/system/reboot":
            threading.Thread(target=lambda: (time.sleep(2), subprocess.run(["reboot"]))).start()
            self.send_json({"rebooting": True})
    def send_json(self, data):
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode("utf-8"))
    def log_message(self, format, *args): pass

if __name__ == "__main__":
    HTTPServer(("127.0.0.1", 8080), Handler).serve_forever()
