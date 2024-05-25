#!/bin/bash



# Check if KEY_PATH environment variable exists or not set
if [ -z "$KEY_PATH" ]; then
    echo "ERROR: Environment variable KEY_PATH is not set."
    exit 5
fi

# if t
if [ $# -lt 1 ]; then
    echo "Failed: missing public  ip"
    exit 5
fi

# creates variables
PUBLIC_IP=$1
PRIVATE_IP=$2

# if there is only one argument then connect to public instance
if [ $# -eq 1 ]; then
    ssh -i "$KEY_PATH" ubuntu@"$PUBLIC_IP"

# if the number of arguments is two, then the first one is the public instance ip and the
# second one is private instance ip

elif [ $# -eq 2 ]; then
    #First connect to the public instance and then connect to private instance from the public.
    ssh -i "$KEY_PATH" -t ubuntu@"$PUBLIC_IP" "ssh -i ameer-new-key-pair1.pem ubuntu@$PRIVATE_IP"

fi