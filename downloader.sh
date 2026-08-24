#!/usr/bin/env bash

set -euo pipefail

BASE_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server"
MAX_SUFFIX=30
DELAY=0.5
MISS_LIMIT=5

# Critical files/folders to preserve
PRESERVE=("allowlist.json" "permissions.json" "server.properties" "worlds")

# Check for required tools
if ! command -v curl &> /dev/null || ! command -v unzip &> /dev/null; then
    echo "Error: curl and unzip are required."
    exit 1
fi

# Check for Docker container
if [[ "$(docker inspect -f '{{.State.Running}}' mcbe)" != "true" ]]; then
    echo "Error: Container 'mcbe' is not running. Please start it before running this script."
    exit 1
fi

# Protection 1: Local ./server check
if [[ -d "./server" ]]; then
    echo "Warning: Directory './server' already exists."
    read -p "Do you want to overwrite it and update? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Update cancelled."
        exit 0
    fi
fi

# Protection 2: Container /mcbe check
if docker exec mcbe ls -A /mcbe | grep -q .; then
    echo -e "\033[31mWARNING: This script only preserves these items: \033[33m ${PRESERVE[*]}. \033[0m"
    echo -e "\033[31mAll other smaller config settings will be reset to default.\033[0m"
    echo "Please backup your config files manually before updating if needed."
    
    read -p "Are you sure you want to proceed with the update? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Update cancelled."
        exit 0
    fi

    # Backup critical items
    BACKUP_DIR="./backup/backup_$(date +%Y%m%d_%H%M%S)"
    echo "Backing up critical files to $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    
    for item in "${PRESERVE[@]}"; do
        if docker exec mcbe test -e "/mcbe/$item"; then
            echo "Backing up $item..."
            docker cp "mcbe:/mcbe/$item" "$BACKUP_DIR/"
        fi
    done
    echo "Backup completed."
fi

printf '\033[33mEnter MCBE version base (e.g. 1.26.32): \033[0m'
read -r VERSION

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid version format. Example: 1.26.32"
    exit 1
fi

echo
echo "--- Probing latest subversion for $VERSION ---"
echo "Please be patient..."

USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/151.0.0.0"

LATEST_VERSION=""

check_version() {
    local version="$1"
    local url="${BASE_URL}-${version}.zip"

    local status
    status=$(curl \
        --silent \
        --head \
        --user-agent "$USER_AGENT" \
        --location \
        --max-time 10 \
        --output /dev/null \
        --write-out "%{http_code}" \
        "$url")

    [[ "$status" == "200" ]]
}

# Check base version
if check_version "$VERSION"; then
    echo "[FOUND] $VERSION"
    LATEST_VERSION="$VERSION"
fi

# Check suffixes
misses=0
for suffix in $(seq 0 "$MAX_SUFFIX"); do
    v="${VERSION}.${suffix}"
    
    # Progress indicator
    echo -n "."
    
    if check_version "$v"; then
        echo -e "\n[FOUND] $v"
        LATEST_VERSION="$v"
        misses=0
    else
        ((misses++))
        if (( misses >= MISS_LIMIT )); then
            echo -e "\nReached limit. Latest found: $LATEST_VERSION"
            break
        fi
    fi
    sleep "$DELAY"
done

if [[ -z "$LATEST_VERSION" ]]; then
    echo "No release found for $VERSION."
    exit 1
fi

echo
echo "Downloading $LATEST_VERSION..."

ZIP_FILE="bedrock-server-${LATEST_VERSION}.zip"
curl -L -O "${BASE_URL}-${LATEST_VERSION}.zip" --user-agent "$USER_AGENT"

echo "Extracting new server files..."
# Recreate server dir
rm -rf ./server
mkdir -p ./server
# hide extract output
unzip -q -o "$ZIP_FILE" -d ./server/
rm "$ZIP_FILE"

echo "Clearing container volume and applying new files..."
docker exec mcbe bash -c "rm -rf /mcbe/*"
docker cp ./server/. mcbe:/mcbe/

echo "Restoring critical files..."
for item in "${PRESERVE[@]}"; do
    if [[ -e "$BACKUP_DIR/$item" ]]; then
        echo "Restoring $item..."
        docker cp "$BACKUP_DIR/$item" "mcbe:/mcbe/"
    fi
done

echo "Restarting container..."
docker restart mcbe

echo "Done. Update complete."
