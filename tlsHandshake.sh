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
echo "Sending Client Hello..."
CLIENT_HELLO=$(curl -s -X POST -H "Content-Type: application/json" -d '{"version": "1.3", "ciphersSuites": ["TLS_AES_128_GCM_SHA256", "TLS_CHACHA20_POLY1305_SHA256"], "message": "Client Hello"}' http://${SERVER_IP}:8080/clienthello)
if [ $? -ne 0 ]; then
    echo "Error sending Client Hello"
    exit 2
fi

CIPHER_SUITE=$(echo "$CLIENT_HELLO" | jq -r '.')
SESSION_ID=$(echo "$CIPHER_SUITE" | jq -r '.sessionID')
SERVER_CERT=$(echo "$CIPHER_SUITE" | jq -r '.serverCert')

# Step 2: Server Certificate Verification
echo "Verifying server certificate..."
echo "$SERVER_CERT"  > cert.pem
# wget -q -O cert_ca_aws.pem https://alonitac.github.io/DevOpsTheHardWay/networking_project/cert-ca-aws.pem
wget https://alonitac.github.io/DevOpsTheHardWay/networking_project/cert-ca-aws.pem
if [ ! -f cert_ca_aws.pem ]; then
    echo "Failed to download CA certificate."
    exit 2
fi
openssl verify -CAfile cert-ca-aws.pem cert.pem
if [ $? -ne 0 ]; then
    echo "Server Certificate is invalid."
    exit 5
fi
rm cert-ca-aws.pem
echo "Generating and encrypting master key..."
MASTER_KEY=$(openssl rand -base64 32)
#ENCRYPTED_MASTER_KEY=$(echo $MASTER_KEY | openssl smime -encrypt -aes-256-cbc -binary -outform DER cert.pem | base64 -w 0)
ENCRYPTED_MASTER_KEY=$(openssl smime -encrypt -aes-256-cbc -in <(echo "$MASTER_KEY") -outform DER cert.pem | base64 -w 0)
# Step 4: Send encrypted master key to server
echo "Sending encrypted master key to server..."
KEY_EXCHANGE=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"sessionID\": \"$SESSION_ID\", \"masterKey\": \"$ENCRYPTED_MASTER_KEY\", \"sampleMessage\":  \"$SAMPLE_MESSAGE\"}" http://$SERVER_IP:8080/keyexchange)
if [ $? -ne 0 ]; then
    echo "Error sending encrypted master key"
    exit 4
fi

# Parse server response
ENCRYPTED_SAMPLE_MESSAGE=$(echo "$KEY_EXCHANGE" | jq -r '.encryptedSampleMessage')

# Step 5: Decrypt sample message and verify
echo "Decrypting and verifying sample message..."
DECRYPTED_SAMPLE_MESSAGE=$(echo $ENCRYPTED_SAMPLE_MESSAGE | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -k "$MASTER_KEY")
if [ "$DECRYPTED_SAMPLE_MESSAGE" != "$SAMPLE_MESSAGE" ]; then
    echo "Server symmetric encryption using the exchanged master-key has failed."
    exit 6
fi

# Step 6: Handshake completed
echo "Client-Server TLS handshake has been completed successfully"

