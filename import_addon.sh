#!/bin/bash

# Minecraft Bedrock Addon Importer Script

# 1. Ask for addon type
read -p "Import type: (R)esource or (B)ehavior? " type
case $type in
  [Rr]* ) folder_type="resource_packs"; json_file="world_resource_packs.json";;
  [Bb]* ) folder_type="behavior_packs"; json_file="world_behavior_packs.json";;
  * ) echo "Invalid option, choose R or B."; exit 1;;
esac

# 2. Ask for addon directory
read -p "Enter path to addon folder: " addon_path
# Remove potential surrounding quotes
addon_path="${addon_path%\"}"
addon_path="${addon_path#\"}"
addon_path="${addon_path%\'}"
addon_path="${addon_path#\'}"

# Validate path exists
if [ ! -d "$addon_path" ]; then
    echo "Directory not found: $addon_path"
    exit 1
fi

# 3. Ask for world name
read -p "Enter world name in container (e.g. AwesomeWorld): " world_name
container_path="mcbe:/mcbe/worlds/$world_name"

# Check if world exists in container
if ! docker exec mcbe ls /mcbe/worlds/"$world_name" > /dev/null 2>&1; then
    echo "World '$world_name' not found in container at /mcbe/worlds/"
    exit 1
fi

# 4. Copy to container
# Create destination directory
docker exec mcbe mkdir -p /mcbe/worlds/"$world_name"/"$folder_type"
# Copy addon
docker cp "$addon_path" mcbe:/mcbe/worlds/"$world_name"/"$folder_type"/

# 5. Extract UUID and version from local manifest.json
manifest="$addon_path/manifest.json"
if [ ! -f "$manifest" ]; then
    echo "manifest.json not found in $addon_path"
    exit 1
fi

uuid=$(jq -r '.header.uuid' "$manifest")
version_array=$(jq -c '.header.version' "$manifest")

echo "Importing pack: $uuid version: $version_array"

# 6. Update world JSON in container
container_json_path="/mcbe/worlds/$world_name/$json_file"

# Check if exists, if not, create empty array
if ! docker exec mcbe ls "$container_json_path" > /dev/null 2>&1; then
    docker exec mcbe bash -c "echo '[]' > $container_json_path"
fi

# Copy container JSON to host to modify
docker cp mcbe:"$container_json_path" .tmp_world_json.json

# Modify JSON: add new entry if not exists
new_entry="{\"pack_id\": \"$uuid\", \"version\": $version_array}"

# Check if pack already exists
if jq -e ".[] | select(.pack_id == \"$uuid\")" .tmp_world_json.json > /dev/null; then
    echo "Pack $uuid already exists in $json_file. Skipping update."
else
    # Append new pack object
    jq ". += [$new_entry]" .tmp_world_json.json > .tmp_updated_json.json
    # Copy back to container
    docker cp .tmp_updated_json.json mcbe:"$container_json_path"
    echo "Updated $json_file successfully."
fi

# Cleanup
rm .tmp_world_json.json 2>/dev/null
rm .tmp_updated_json.json 2>/dev/null

echo "Done."
