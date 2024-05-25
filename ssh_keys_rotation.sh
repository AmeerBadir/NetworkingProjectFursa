#!/bin/bash

if [ $# -ne 1 ]; then

  echo "Missing IP address"

  exit 1

fi
# generate key check
ssh-keygen -t rsa -b 2048 -f check-key.pem -N ""





