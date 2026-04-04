#!/bin/sh

# =========================
# FUNCTIONS (placeholders)
# =========================

install_server() {
echo "Running installer..."
echo "eula=true" > eula.txt



echo "=== Setting up server properties ==="
echo ""

# -------------------------------
# Menu function (number selection)
# -------------------------------
menu() {
  var_name=$1
  prompt=$2
  default=$3
  shift 3
  options="$@"

  echo "$prompt"
  i=1
  for opt in $options; do
    echo "  $i) $opt"
    i=$((i+1))
  done

  printf "Select option (default: %s): " "$default"
  read choice

  case $choice in
    1) eval "$var_name=$(echo $options | cut -d' ' -f1)" ;;
    2) eval "$var_name=$(echo $options | cut -d' ' -f2)" ;;
    3) eval "$var_name=$(echo $options | cut -d' ' -f3)" ;;
    4) eval "$var_name=$(echo $options | cut -d' ' -f4)" ;;
    *)
      eval "$var_name=$default"
      ;;
  esac

  echo ""
}

# -------------------------------
# Numeric input
# -------------------------------
ask_number() {
  var_name=$1
  prompt=$2
  default=$3

  printf "%s [%s]: " "$prompt" "$default"
  read input

  if [ -z "$input" ]; then
    eval "$var_name=$default"
  elif echo "$input" | grep -Eq '^[0-9]+$'; then
    eval "$var_name=$input"
  else
    echo "Invalid input → using default ($default)"
    eval "$var_name=$default"
  fi
}

# -------------------------------
# Free text input
# -------------------------------
ask_text() {
  var_name=$1
  prompt=$2
  default=$3

  printf "%s [%s]: " "$prompt" "$default"
  read input

  if [ -z "$input" ]; then
    eval "$var_name=\"$default\""
  else
    eval "$var_name=\"$input\""
  fi
}

# -------------------------------
# REQUIRED input
# -------------------------------
ask_required() {
  var_name=$1
  prompt=$2

  while true; do
    printf "%s: " "$prompt"
    read input

    if [ -n "$input" ]; then
      eval "$var_name=\"$input\""
      break
    else
      echo "This field is required!"
    fi
  done
}

# -------------------------------
# Inputs
# -------------------------------

menu GAMEMODE "Gamemode" "survival" survival creative adventure spectator
menu HARDCORE "Hardcore" "false" true false
menu DIFFICULTY "Difficulty" "hard" peaceful easy normal hard
menu ONLINE_MODE "Online Mode" "false" true false

ask_text SEED "World Seed (any value allowed)" ""
ask_required LEVEL_NAME "Level Name (REQUIRED)"
ask_text MOTD "MOTD" "A Minecraft Server"

ask_number SIM_DISTANCE "Simulation Distance" "10"
ask_number VIEW_DISTANCE "Render Distance (view-distance)" "7"
ask_number MAX_PLAYERS "Max Players" "20"

echo ""
echo "Generating server.properties..."
echo ""

# -------------------------------
# Generate file
# -------------------------------

cat > server.properties <<EOF
accepts-transfers=false
allow-flight=false
broadcast-console-to-ops=true
broadcast-rcon-to-ops=true
bug-report-link=
debug=false
difficulty=$DIFFICULTY
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
gamemode=$GAMEMODE
generate-structures=true
generator-settings={}
hardcore=$HARDCORE
hide-online-players=false
initial-disabled-packs=
initial-enabled-packs=vanilla
level-name=$LEVEL_NAME
level-seed=$SEED
level-type=minecraft\:normal
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
max-players=$MAX_PLAYERS
max-tick-time=60000
max-world-size=29999984
motd=$MOTD
network-compression-threshold=256
online-mode=$ONLINE_MODE
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
simulation-distance=$SIM_DISTANCE
spawn-protection=16
status-heartbeat-interval=0
sync-chunk-writes=true
text-filtering-config=
text-filtering-version=0
use-native-transport=true
view-distance=$VIEW_DISTANCE
white-list=false
EOF

echo "Server properties have been set up successfully!"

echo ""
echo "=== Installing the latest version of PaperMC ==="

# Get latest version + build
LATEST_VERSION=$(curl -s https://api.papermc.io/v2/projects/paper | grep -oP '"versions":\[\K[^\]]+' | tr ',' '\n' | tail -n 1 | tr -d '"')
LATEST_BUILD=$(curl -s https://api.papermc.io/v2/projects/paper/versions/$LATEST_VERSION | grep -oP '"builds":\[\K[^\]]+' | tr ',' '\n' | tail -n 1)

# Update Paper
echo "Downloading latest PaperMC ($LATEST_VERSION)..."

if curl -f -L -o paper.jar \
https://api.papermc.io/v2/projects/paper/versions/$LATEST_VERSION/builds/$LATEST_BUILD/downloads/paper-$LATEST_VERSION-$LATEST_BUILD.jar
then
  echo "PaperMC installed successfully"
else
  echo "Failed to install PaperMC"
fi


echo "=== Installing Geyser & Floodgate ==="

mkdir -p plugins

# Update Geyser
echo "Downloading Geyser..."
if curl -f -L -o plugins/Geyser.jar https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot
then
  echo "Geyser installed successfully"
else
  echo "Failed to install Geyser"
fi

# Update Floodgate
echo "Downloading Floodgate..."
if curl -f -L -o plugins/Floodgate.jar https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot
then
  echo "Floodgate installed successfully"
else
  echo "Failed to install Floodgate"
fi


echo "=== Installing Via Plugins (Hangar) ==="

mkdir -p plugins

# -------------------------------
# Function: Install + Show Version
# -------------------------------
install_hangar () {
  NAME=$1
  PROJECT=$2
  FILE=$3

  echo "Checking $NAME..."

  # Fetch latest version info
  DATA=$(curl -s "https://hangar.papermc.io/api/v1/projects/$PROJECT/versions")

  VERSION=$(echo "$DATA" | grep -oP '"name":"\K[^"]+' | head -n 1)
  URL=$(echo "$DATA" | grep -oP '"downloadUrl":"\K[^"]+' | head -n 1)

  if [ -z "$URL" ] || [ -z "$VERSION" ]; then
    echo "Failed to fetch $NAME info"
    return
  fi

  echo "Installing $NAME version $VERSION..."

  if curl -f -L -o "$FILE" "$URL"; then
    echo "Installed $NAME version $VERSION"
  else
    echo "Failed to install $NAME"
  fi
}

# -------------------------------
# Plugins
# -------------------------------

install_hangar "ViaVersion" "ViaVersion/ViaVersion" "plugins/ViaVersion.jar"
install_hangar "ViaBackwards" "ViaVersion/ViaBackwards" "plugins/ViaBackwards.jar"
install_hangar "ViaRewind" "ViaVersion/ViaRewind" "plugins/ViaRewind.jar"

echo "=== Done ==="
}

update_server() {
echo "Running updater..."
echo "eula=true" > eula.txt
rm -rf plugins/*
echo "=== Updating to the latest version of PaperMC ==="

# Get latest version + build
LATEST_VERSION=$(curl -s https://api.papermc.io/v2/projects/paper | grep -oP '"versions":\[\K[^\]]+' | tr ',' '\n' | tail -n 1 | tr -d '"')
LATEST_BUILD=$(curl -s https://api.papermc.io/v2/projects/paper/versions/$LATEST_VERSION | grep -oP '"builds":\[\K[^\]]+' | tr ',' '\n' | tail -n 1)

# Update Paper
echo "Downloading latest PaperMC ($LATEST_VERSION)..."

if curl -f -L -o paper.jar \
https://api.papermc.io/v2/projects/paper/versions/$LATEST_VERSION/builds/$LATEST_BUILD/downloads/paper-$LATEST_VERSION-$LATEST_BUILD.jar
then
  echo "PaperMC updated successfully"
else
  echo "Failed to install PaperMC"
fi


echo "=== Installing Geyser & Floodgate ==="

mkdir -p plugins

# Update Geyser
echo "Downloading Geyser..."
if curl -f -L -o plugins/Geyser.jar https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot
then
  echo "Geyser updated successfully"
else
  echo "Failed to install Geyser"
fi

# Update Floodgate
echo "Downloading Floodgate..."
if curl -f -L -o plugins/Floodgate.jar https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot
then
  echo "Floodgate updated successfully"
else
  echo "Failed to install Floodgate"
fi


echo "=== Updating Via Plugins (Hangar) ==="

mkdir -p plugins

# -------------------------------
# Function: Install + Show Version
# -------------------------------
install_hangar () {
  NAME=$1
  PROJECT=$2
  FILE=$3

  echo "Checking $NAME..."

  # Fetch latest version info
  DATA=$(curl -s "https://hangar.papermc.io/api/v1/projects/$PROJECT/versions")

  VERSION=$(echo "$DATA" | grep -oP '"name":"\K[^"]+' | head -n 1)
  URL=$(echo "$DATA" | grep -oP '"downloadUrl":"\K[^"]+' | head -n 1)

  if [ -z "$URL" ] || [ -z "$VERSION" ]; then
    echo "Failed to fetch $NAME info"
    return
  fi

  echo "Installing $NAME version $VERSION..."

  if curl -f -L -o "$FILE" "$URL"; then
    echo "Installed $NAME version $VERSION"
  else
    echo "Failed to install $NAME"
  fi
}

# -------------------------------
# Plugins
# -------------------------------

install_hangar "ViaVersion" "ViaVersion/ViaVersion" "plugins/ViaVersion.jar"
install_hangar "ViaBackwards" "ViaVersion/ViaBackwards" "plugins/ViaBackwards.jar"
install_hangar "ViaRewind" "ViaVersion/ViaRewind" "plugins/ViaRewind.jar"

echo "=== Done ==="

}

start_server() {
echo "Starting server..."
echo "=== Minecraft Server RAM Selector ==="

# Minimum RAM menu
echo "Select MIN RAM (Default 1 G):"
for i in $(seq 1 10); do
  echo "$i) ${i} G"
done
read -p "Enter choice [1-10]: " MIN_CHOICE

case $MIN_CHOICE in
  1) MIN_RAM="1G" ;;
  2) MIN_RAM="2G" ;;
  3) MIN_RAM="3G" ;;
  4) MIN_RAM="4G" ;;
  5) MIN_RAM="5G" ;;
  6) MIN_RAM="6G" ;;
  7) MIN_RAM="7G" ;;
  8) MIN_RAM="8G" ;;
  9) MIN_RAM="9G" ;;
  10) MIN_RAM="10G" ;;
  *) echo "Invalid choice, defaulting MIN RAM to 1 G"; MIN_RAM="1G" ;;
esac

# Maximum RAM menu
echo "Select MAX RAM (Default 3 G):"
for i in $(seq 1 10); do
  echo "$i) ${i} G"
done
read -p "Enter choice [1-10]: " MAX_CHOICE

case $MAX_CHOICE in
  1) MAX_RAM="1G" ;;
  2) MAX_RAM="2G" ;;
  3) MAX_RAM="3G" ;;
  4) MAX_RAM="4G" ;;
  5) MAX_RAM="5G" ;;
  6) MAX_RAM="6G" ;;
  7) MAX_RAM="7G" ;;
  8) MAX_RAM="8G" ;;
  9) MAX_RAM="9G" ;;
  10) MAX_RAM="10G" ;;
  *) echo "Invalid choice, defaulting MAX RAM to 3 G"; MAX_RAM="3G" ;;
esac

# Ensure MAX is not less than MIN
if [ ${MAX_RAM%G} -lt ${MIN_RAM%G} ]; then
  echo "MAX RAM cannot be less than MIN RAM. Adjusting MAX RAM to $MIN_RAM"
  MAX_RAM=$MIN_RAM
fi

echo "Starting server with MIN=$MIN_RAM and MAX=$MAX_RAM..."
java -Xms$MIN_RAM -Xmx$MAX_RAM -jar paper.jar nogui

}

# =========================
# MAIN MENU LOOP
# =========================

while true; do
  echo ""
  echo "=== PaperMC Server Setup Script ==="
  echo "1) Install PaperMC Server"
  echo "2) Update PaperMC Server"
  echo "3) Run PaperMC Server"
  echo "4) Quit"
  echo ""

  printf "Enter choice: "
  read choice

  case $choice in
    1) install_server ;;
    2) update_server ;;
    3) start_server ;;
    4) echo "Goodbye!"; exit 0 ;;
    *) echo "Invalid entry. Try again." ;;
  esac
done
