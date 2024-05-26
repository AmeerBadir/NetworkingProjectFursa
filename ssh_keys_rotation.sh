#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Missing IP address"
  exit 1
fi

# generate key check
# ssh-keygen -t rsa -b 2048 -f check-key.pem -N ""

# an order to do rotation, we need to genrate a new key and then add it in authorized key
# in private instance


# create a file to copy to the current key to it
touch copy-key.pem copy-key.pem.pub

# if the key exists, then copy it 
if [ -e ameer-new-key-pair1.pem ]; then
  cat ameer-new-key-pair1.pem > copy-key.pem
  cat ameer-new-key-pair1.pem.pub > copy-key.pem.pub
fi
chmod 400 copy-key.pem
# create a key and override the pervious one
sh-keygen -t rsa -b 4096 -f ameer-new-key-pair1.pem -N ""


cat ameer-new-key-pair1.pem.pub | ssh -o StrictHostKeyChecking=accept-new -i copy-key.pem ubuntu@"$1" "cat > ~/.ssh/authorized_keys"
