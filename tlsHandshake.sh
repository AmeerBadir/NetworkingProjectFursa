#!/bin/bash
if [ $# -ne 1 ]; then
    echo "Usage: $0 <server-ip>"
    exit 1
fi

SERVER_IP=$1
SESSION_ID=""
MASTER_KEY=""
SAMPLE_MESSAGE="Hi server, please encrypt me and send to client!"

# Step 1: Client Hello Msg
echo "Step 1: Client Hello ..."
CLIENT_HELLO=$(curl -s -X POST -H "Content-Type: application/json" -d '{"version": "1.3", "ciphersSuites": ["TLS_AES_128_GCM_SHA256", "TLS_CHACHA20_POLY1305_SHA256"], "message": "Client Hello"}' http://$SERVER_IP:8080/clienthello)
if [ $? -ne 0 ]; then
    echo "Failed to send Client Hello"
    exit 2
fi


echo "Step 2: Server Hello..."
CLIENT_HELLO=$(echo "$CLIENT_HELLO" | jq -r '.')
SESSION_ID=$(echo "$CLIENT_HELLO" | jq -r '.sessionID')
SERVER_CERT=$(echo "$CLIENT_HELLO" | jq -r '.serverCert')
echo "$SERVER_CERT" > cert.pem


# Step 3:  Download CA certificate and Server Verification
echo "Download CA certificate and Server Verification"
echo "$SERVER_CERT" > cert.pem
wget -q -O cert-ca-aws.pem https://alonitac.github.io/DevOpsTheHardWay/networking_project/cert-ca-aws.pem
openssl verify -CAfile cert-ca-aws.pem cert.pem
if [ $? -ne 0 ]; then
    echo "Server Certificate  Failed."
    exit 5
fi



# Step 4: Client-Server master-key exchange
echo "Step 4: Generating and sending master key..."
MASTER_KEY=$(openssl rand -base64 32)
ENCRYPTED_MASTER_KEY=$(openssl smime -encrypt -aes-256-cbc -in <(echo "$MASTER_KEY") -outform DER cert.pem | base64 -w 0)



echo "Step 5: Server verification message..."


KEY_EXCHANGE=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"sessionID\": \"$SESSION_ID\", \"masterKey\": \"$ENCRYPTED_MASTER_KEY\", \"sampleMessage\": \"$SAMPLE_MESSAGE\"}" http://$SERVER_IP:8080/keyexchange)



# Step 6:Decrypt sample message and verify
echo "Step 6: Decrypt sample message and verify..."

ENCRYPTED_SAMPLE_MESSAGE=$(echo "$KEY_EXCHANGE" | jq -r '.encryptedSampleMessage')
DECRYPTED_SAMPLE_MESSAGE=$(echo "$ENCRYPTED_SAMPLE_MESSAGE" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -k "$MASTER_KEY")

if [ "$DECRYPTED_SAMPLE_MESSAGE" != "$SAMPLE_MESSAGE" ]; then
    echo "Server symmetric encryption using the exchanged master-key has failed."
    exit 6
fi
#  Handshake completed
echo "Client-Server TLS handshake has been completed successfully"
