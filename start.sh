#!/bin/bash
set -e

cd /mcbe

echo "Starting MCBE server..."

if [ ! -f ./bedrock_server ]; then
    echo "ERROR: bedrock_server not found in /mcbe"
    sleep infinity
fi

chmod +x ./bedrock_server

export LD_LIBRARY_PATH=.

./bedrock_server