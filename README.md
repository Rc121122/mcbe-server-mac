## Minecraft Bedrock Server on Docker

### Build for MacOS with apple sillicon
Issue: minecraft bedrock doesn't have official arm64 build, so we need to emulate x86-64 on apple sillicon. Rosetta 2 is used for near native performance. For other linux arm64 users (eg: Raspberry Pi), you can use box64 for emulation

### Requirements
- Docker desktop
    - enable rosetta 2 for best performance on x86-64 emulation on MacOS apple silicon
- Official Minecraft Bedrock Server files (https://www.minecraft.net/en-us/download/server/bedrock) 
Download Ubuntu Linux x86-64 version and extract the files to this folder, rename as /server/

### Installation
1. Build image with dockerfile
    ```bash
    docker build --platform linux/amd64 -t mcbe:latest .
    ```

2. Create a volume for persistent data
    ```bash
    docker volume create mcbe-data
    ```

3. Run the container
    ```bash
    docker run -dit \
    --name mcbe \
    --platform linux/amd64 \
    -p 19132:19132/udp \
    -v mcbe-data:/mcbe \
    mcbe:latest
    ```

4. Use *download.sh* to find a version, it will automatically download, extract and copy into volume and restart the container.
    ```bash
    ./download.sh
    ```

5. All set! The server should be running now, you can modify settings, import worlds and restart the container to apply changes. See [TIPS](#tips) for more details.

### TIPS:
- Enter console
    ```bash
    docker attach mcbe
    ```
    - you can manage the game inside the console, eg:
        ```op <player>``` give operator permissions to a player
        ```stop``` stop the server
        ```list``` list all players online
        ```help <int:1~3>``` view more commands in help pages 1~3
        Do not press Ctrl+C to exit the console, it will stop the server. Just simply close the terminal window.

- Update server version
    - Use *download.sh* to find a version, it will automatically download, extract and copy into volume and restart the container.
    ```bash
    ./download.sh
    ```
    WARNING: this script only perserve these items: allowlist.json, permissions.json, server.properties, /worlds. All other smaller config settings will be reset to default. Please backup your config files before updating. 
