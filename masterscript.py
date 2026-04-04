#!/usr/bin/env python3
import os
import subprocess
import sys
import json
import urllib.request
from pathlib import Path
import shutil



def fetch_json(url):
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0"}
    )
    with urllib.request.urlopen(req) as response:
        return json.load(response)
# =========================
# DOWNLOAD WITH PROGRESS BAR
# =========================

def download_file(url, dest):
    try:
        # ADD USER AGENT (THIS FIXES 403)
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "Mozilla/5.0"}
        )

        with urllib.request.urlopen(req) as response:
            total_size = int(response.getheader('Content-Length', 0))
            downloaded = 0
            chunk_size = 8192

            with open(dest, 'wb') as f:
                while True:
                    chunk = response.read(chunk_size)
                    if not chunk:
                        break
                    f.write(chunk)
                    downloaded += len(chunk)

                    if total_size > 0:
                        percent = downloaded * 100 // total_size
                        bar_len = 30
                        filled = int(bar_len * downloaded // total_size)
                        bar = "#" * filled + "-" * (bar_len - filled)

                        sys.stdout.write(
                            f"\rDownloading {os.path.basename(dest)} [{bar}] {percent}%"
                        )
                        sys.stdout.flush()

        print(f"\nDownloaded {dest}")
        return True

    except Exception as e:
        print(f"\nFailed: {e}")
        return False
# =========================
# INPUT FUNCTIONS
# =========================

def menu(prompt, options, default):
    print(prompt)
    for i, opt in enumerate(options, 1):
        print(f"  {i}) {opt}")
    choice = input(f"Select option (default: {default}): ").strip()
    return options[int(choice)-1] if choice.isdigit() and 1 <= int(choice) <= len(options) else default

def ask_number(prompt, default):
    val = input(f"{prompt} [{default}]: ").strip()
    return val if val.isdigit() else default

def ask_text(prompt, default):
    val = input(f"{prompt} [{default}]: ").strip()
    return val if val else default

def ask_required(prompt):
    while True:
        val = input(f"{prompt}: ").strip()
        if val:
            return val
        print("This field is required!")

# =========================
# HANGAR INSTALL (FINAL FIX)
# =========================
def install_hangar(name, project, file_path):
    print(f"Checking {name}...")

    try:
        data = fetch_json(f"https://hangar.papermc.io/api/v1/projects/{project}/versions")

        # FIX: actual data is inside "result"
        versions = data.get("result", [])

        if not versions:
            print(f"No versions found for {name}")
            return

        # newest version (same as head -n 1)
        version_data = versions[0]
        version = version_data.get("name")

        downloads = version_data.get("downloads", {})

        url = None

        for platform in ["PAPER", "SPIGOT", "BUKKIT"]:
            if platform in downloads:
                url = downloads[platform].get("downloadUrl")
                if url:
                    break

        if not url:
            print(f"No valid download URL for {name}")
            return

    except Exception as e:
        print(f"Failed to fetch {name}: {e}")
        return

    print(f"Installing {name} version {version}...")

    if download_file(url, file_path):
        print(f"Installed {name} version {version}")
    else:
        print(f"Failed to install {name}")


# =========================
# INSTALL SERVER
# =========================

def install_server():
    print("Running installer...")
    Path("eula.txt").write_text("eula=true\n")

    print("\n=== Server Setup ===\n")

    GAMEMODE = menu("Gamemode", ["survival","creative","adventure","spectator"], "survival")
    HARDCORE = menu("Hardcore", ["true","false"], "false")
    DIFFICULTY = menu("Difficulty", ["peaceful","easy","normal","hard"], "hard")
    ONLINE_MODE = menu("Online Mode", ["true","false"], "false")

    SEED = ask_text("World Seed", "")
    LEVEL_NAME = ask_required("Level Name")
    MOTD = ask_text("MOTD", "A Minecraft Server")

    SIM_DISTANCE = ask_number("Simulation Distance", "10")
    VIEW_DISTANCE = ask_number("Render Distance", "7")
    MAX_PLAYERS = ask_number("Max Players", "20")

    print("\nGenerating server.properties...\n")

    Path("server.properties").write_text(f"""accepts-transfers=false
allow-flight=false
broadcast-console-to-ops=true
broadcast-rcon-to-ops=true
bug-report-link=
debug=false
difficulty={DIFFICULTY}
enable-code-of-conduct=false
enable-jmx-monitoring=false
enable-query=false
enable-rcon=false
enable-status=true
enforce-secure-profile=true
enforce-whitelist=false
entity-broadcast-range-percentage=100
force-gamemode=false
function-permission-level=2
gamemode={GAMEMODE}
generate-structures=true
generator-settings={{}}
hardcore={HARDCORE}
hide-online-players=false
initial-disabled-packs=
initial-enabled-packs=vanilla
level-name={LEVEL_NAME}
level-seed={SEED}
level-type=minecraft:normal
log-ips=true
management-server-allowed-origins=
management-server-enabled=false
management-server-host=localhost
management-server-port=0
management-server-secret=CHANGE_ME
management-server-tls-enabled=true
management-server-tls-keystore=
management-server-tls-keystore-password=
max-chained-neighbor-updates=1000000
max-players={MAX_PLAYERS}
max-tick-time=60000
max-world-size=29999984
motd={MOTD}
network-compression-threshold=256
online-mode={ONLINE_MODE}
op-permission-level=4
pause-when-empty-seconds=-1
player-idle-timeout=0
prevent-proxy-connections=false
query.port=25565
rate-limit=0
rcon.password=
rcon.port=25575
region-file-compression=deflate
require-resource-pack=false
resource-pack=
resource-pack-id=
resource-pack-prompt=
resource-pack-sha1=
server-ip=
server-port=25565
simulation-distance={SIM_DISTANCE}
spawn-protection=16
status-heartbeat-interval=0
sync-chunk-writes=true
text-filtering-config=
text-filtering-version=0
use-native-transport=true
view-distance={VIEW_DISTANCE}
white-list=false
""")

    print("Installing PaperMC...")

    data = fetch_json("https://api.papermc.io/v2/projects/paper")
    version = data["versions"][-1]
    builds = fetch_json(f"https://api.papermc.io/v2/projects/paper/versions/{version}")
    build = builds["builds"][-1]

    url = f"https://api.papermc.io/v2/projects/paper/versions/{version}/builds/{build}/downloads/paper-{version}-{build}.jar"
    download_file(url, "paper.jar")

    Path("plugins").mkdir(exist_ok=True)

    download_file("https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot","plugins/Geyser.jar")
    download_file("https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot","plugins/Floodgate.jar")

    install_hangar("ViaVersion","ViaVersion/ViaVersion","plugins/ViaVersion.jar")
    install_hangar("ViaBackwards","ViaVersion/ViaBackwards","plugins/ViaBackwards.jar")
    install_hangar("ViaRewind","ViaVersion/ViaRewind","plugins/ViaRewind.jar")

    print("=== Installation Complete ===")

# =========================
# UPDATE SERVER
# =========================

def update_server():
    print("Running updater...")
    Path("eula.txt").write_text("eula=true\n")

    plugins = Path("plugins")

    if plugins.exists():
        print("Deleting ALL plugin contents...")
        for item in plugins.iterdir():
            if item.is_file():
                item.unlink()
            else:
                shutil.rmtree(item)
    else:
        plugins.mkdir()

    print("Updating PaperMC...")

    data = fetch_json("https://api.papermc.io/v2/projects/paper")
    version = data["versions"][-1]
    builds = fetch_json(f"https://api.papermc.io/v2/projects/paper/versions/{version}")
    build = builds["builds"][-1]

    url = f"https://api.papermc.io/v2/projects/paper/versions/{version}/builds/{build}/downloads/paper-{version}-{build}.jar"
    download_file(url, "paper.jar")

    print("Reinstalling plugins...")

    download_file("https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot","plugins/Geyser.jar")
    download_file("https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot","plugins/Floodgate.jar")

    install_hangar("ViaVersion","ViaVersion/ViaVersion","plugins/ViaVersion.jar")
    install_hangar("ViaBackwards","ViaVersion/ViaBackwards","plugins/ViaBackwards.jar")
    install_hangar("ViaRewind","ViaVersion/ViaRewind","plugins/ViaRewind.jar")

    print("=== Update Complete ===")

# =========================
# START SERVER
# =========================

def start_server():
    min_ram = input("MIN RAM (default 1): ") or "1"
    max_ram = input("MAX RAM (default 3): ") or "3"

    MIN = f"{min_ram}G"
    MAX = f"{max_ram}G"

    if int(MAX[:-1]) < int(MIN[:-1]):
        MAX = MIN

    subprocess.run(["java", f"-Xms{MIN}", f"-Xmx{MAX}", "-jar", "paper.jar", "nogui"])

# =========================
# MAIN MENU
# =========================

def main():
    while True:
        print("\n=== PaperMC Manager ===")
        print("1) Install")
        print("2) Update")
        print("3) Start")
        print("4) Quit")

        c = input("Choice: ").strip()

        if c == "1":
            install_server()
        elif c == "2":
            update_server()
        elif c == "3":
            start_server()
        elif c == "4":
            sys.exit()
        else:
            print("Invalid")

if __name__ == "__main__":
    main()
