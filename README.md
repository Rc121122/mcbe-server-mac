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
    docker build -t mcbe .
    ```

2. Create a volume for persistent data
    ```bash
    docker volume create mcbe_data
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

4. Copy the server files into the container
    ```bash
    docker cp ./server/. mcbe:/mcbe/
    ```

5. restart the container
    ```bash
    docker restart mcbe
    ```

TIPS:
- Enter console
    ```bash
    docker attach mcbe
    ```
    - you can manage the game inside the console, eg:
        ```op <player>``` give operator permissions to a player
        ```stop``` stop the server
        ```list``` list all players online
- Import your world or update game version
    0. backup your world folder
    ```bash
    docker cp mcbe:/mcbe/worlds/<your world name> <your host destination folder>
    ```
    1. remove your container
    ```bash
    docker rm -f mcbe
    ```
    2. copy your world folder into /server/worlds/
    3. rebuilt the image and run the container again
    4. copy the new server files into container
    ```bash
    docker cp ./server/. mcbe:/mcbe/
    ```
    5. restart the container
    ```bash
    docker restart mcbe
    ```
- Modify some configuration files, don't need to rebuild, just copy the modified files into the container and restart it. (Warning: cp is partial overwrite, it will overwrite the old config files with same name)
    ```bash
    docker cp ./server/. mcbe:/mcbe/
    docker restart mcbe
    ```
