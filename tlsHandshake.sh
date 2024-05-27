#!/bin/bash

#Check if instance ip exist
if [ $# -ne 1 ]; then
    echo "Error: Missing public instance ip"
    exit 1
fi

SERVER_IP=$1
SESSION_ID=""
MASTER_KEY=""
SAMPLE_MESSAGE="Hi server, please encrypt me and send to client!"

# Step 1: Client Hello
SERVER_IP=$1
SESSION_ID=""
MASTER_KEY=""
SAMPLE_MESSAGE="Hi server, please encrypt me and send to client!"

# Step 1: Client Hello
echo "Sending Client Hello..."
CLIENT_HELLO=$(curl -s -X POST -H "Content-Type: application/json" -d '{"version": "1.3", "ciphersSuites": ["TLS_AES_128_GCM_SHA256", "TLS_CHACHA20_POLY1305_SHA256"], "message": "Client Hello"}' http://${SERVER_IP}:8080/clienthello)
if [ $? -ne 0 ]; then
    echo "Error sending Client Hello"
    exit 2
fi

CIPHER_SUITE=$(echo $CLIENT_HELLO | jq -r '.cipherSuite')
SESSION_ID=$(echo $CLIENT_HELLO | jq -r '.sessionID')
SERVER_CERT=$(echo $CLIENT_HELLO | jq -r '.serverCert')

# Step 2: Server Certificate Verification
echo "Verifying server certificate..."
echo $SERVER_CERT | base64 -d > cert.pem
