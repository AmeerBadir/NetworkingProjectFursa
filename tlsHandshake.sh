#!/bin/bash

#Check if instance ip exist
if [ $# -ne 1 ]; then
    echo "Error: Missing public instance ip"
    exit 1
fi
