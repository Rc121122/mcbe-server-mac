#!/usr/bin/env bash

set -u

BASE_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server"

MAX_SUFFIX=30
DELAY=0.8
MISS_LIMIT=5

read -rp "Enter MCBE version (e.g. 1.26.32): " VERSION

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid version format. Example: 1.26.32"
    exit 1
fi

echo
echo "Scanning: $VERSION"
echo

USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36"

FOUND=()

check_version() {
    local version="$1"
    local url="${BASE_URL}-${version}.zip"

    local status

    status=$(curl \
        --silent \
        --head \
        --user-agent "$USER_AGENT" \
        --location \
        --max-time 15 \
        --output /dev/null \
        --write-out "%{http_code}" \
        "$url")

    if [[ "$status" == "200" ]]; then
        echo "[FOUND] $version"
        FOUND+=("$version")
        return 0
    else
        echo "[MISS ] $version"
        return 1
    fi
}

# --------------------------------------------------
# 1.26.32.zip
# --------------------------------------------------

check_version "$VERSION"
sleep "$DELAY"

# --------------------------------------------------
# 1.26.32.0.zip ... 1.26.32.30.zip
# --------------------------------------------------

misses=0

for suffix in $(seq 0 "$MAX_SUFFIX"); do

    version="${VERSION}.${suffix}"

    if check_version "$version"; then
        misses=0
    else
        ((misses++))

        if (( misses >= MISS_LIMIT )); then
            echo
            echo "Stopping after $MISS_LIMIT consecutive misses."
            break
        fi
    fi

    sleep "$DELAY"
done

echo
echo "================================"
echo "Available versions for $VERSION"
echo "================================"

if (( ${#FOUND[@]} == 0 )); then
    echo "None found."
else
    printf '%s\n' "${FOUND[@]}"
fi