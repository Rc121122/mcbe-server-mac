## Migrate from Docker Desktop to OrbStack
### Why migrate?
- Orbstack is a lightweight alternative to Docker Desktop for MacOS, which provides better performance and lower resource usage. It is especially beneficial for running x86-64 emulation (Rosetta 2) on Apple Silicon Macs.
- To eliminate maximum overhead for mcbe server, we can migrate from Docker Desktop to Orbstack. This will improve performance and reduce resource consumption.
### Steps
1. Stop Docker Desktop and launch Orbstack.
2. Change docker cli context
```bash
docker context use orbstack
# validate
docker context ls
# it should show orbstack in use
```
3. rebuild the mcbe image using same docker commands as usual, see [README.md](README.md) for instructions.