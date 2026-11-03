#!/usr/bin/env python3
"""
OpenRUS OS - GitHub Update Center Engine
Enables in-place OTA system updates directly from a GitHub repository
without requiring any USB reflashing or reinstallation.
"""

import os
import sys
import json
import urllib.request
import urllib.error
import subprocess
import hashlib
import shutil

CONFIG_FILE = "/etc/openrus/updater.json"
DEFAULT_REPO = "OpenRUS/openrus-core"
CURRENT_VERSION_FILE = "/etc/openrus/version"

def get_current_version():
    if os.path.exists(CURRENT_VERSION_FILE):
        with open(CURRENT_VERSION_FILE, "r") as f:
            return f.read().strip()
    return "1.0.0"

def load_config():
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {"repo": DEFAULT_REPO, "auto_apply": False}

def check_for_updates():
    cfg = load_config()
    repo = cfg.get("repo", DEFAULT_REPO)
    current_ver = get_current_version()
    
    print(f"[*] OpenRUS GitHub Update Center")
    print(f"[*] Current System Version: {current_ver}")
    print(f"[*] Querying GitHub Repository: https://github.com/{repo} ...")
    
    url = f"https://api.github.com/repos/{repo}/releases/latest"
    req = urllib.request.Request(
        url,
        headers={"User-Agent": f"OpenRUS-OS-Updater/{current_ver}"}
    )
    
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode())
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print("[INFO] No public releases found yet on the repository.")
            print("[INFO] To publish updates, create a GitHub Release with 'update.tar.gz' attached.")
            return None
        print(f"[ERROR] GitHub API returned HTTP {e.code}: {e.reason}")
        return None
    except Exception as e:
        print(f"[ERROR] Failed to connect to GitHub: {e}")
        return None

    remote_tag = data.get("tag_name", "").lstrip("v")
    print(f"[*] Latest Remote Release on GitHub: {remote_tag}")
    
    if remote_tag != current_ver and remote_tag:
        print(f"[!] NEW UPDATE FOUND: v{remote_tag} (Current is v{current_ver})")
        print(f"[*] Release Notes:\n{data.get('body', 'No release notes provided.')}")
        return data
    else:
        print("[OK] Your OpenRUS system is completely up to date!")
        return None

def apply_update(release_data):
    assets = release_data.get("assets", [])
    update_asset = None
    for a in assets:
        if a.get("name") in ["openrus-update.tar.gz", "update.tar.gz"]:
            update_asset = a
            break
            
    if not update_asset:
        print("[WARN] No 'openrus-update.tar.gz' archive found in this GitHub release.")
        return False
        
    download_url = update_asset.get("browser_download_url")
    print(f"[*] Downloading update package from: {download_url}...")
    
    tmp_archive = "/tmp/openrus-update.tar.gz"
    urllib.request.urlretrieve(download_url, tmp_archive)
    print("[*] Download complete. Extracting and applying update in-place...")
    
    extract_dir = "/tmp/openrus-update-extracted"
    os.makedirs(extract_dir, exist_ok=True)
    subprocess.run(["tar", "-xzf", tmp_archive, "-C", extract_dir], check=True)
    
    # Run post-install hook if present
    post_install = os.path.join(extract_dir, "post-install.sh")
    if os.path.exists(post_install):
        print("[*] Executing update post-install scripts...")
        os.chmod(post_install, 0o755)
        subprocess.run([post_install], check=True)
        
    # Update local version record
    new_version = release_data.get("tag_name", "").lstrip("v")
    os.makedirs(os.path.dirname(CURRENT_VERSION_FILE), exist_ok=True)
    with open(CURRENT_VERSION_FILE, "w") as f:
        f.write(new_version + "\n")
        
    print(f"[SUCCESS] OpenRUS successfully updated to v{new_version} without rebooting!")
    return True

if __name__ == "__main__":
    release = check_for_updates()
    if release and "--apply" in sys.argv:
        apply_update(release)
    elif release:
        print("\nTo install this update immediately, run:")
        print("  sudo openrus-updater --apply")
