#!/bin/bash



# Check if KEY_PATH environment variable exists or not set
if [ -z "$KEY_PATH" ]; then
    echo "ERROR: Environment variable KEY_PATH is not set."
    exit 5
fi

