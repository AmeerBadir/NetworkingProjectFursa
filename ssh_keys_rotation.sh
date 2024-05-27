#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Missing IP address"
  exit 1
fi

# an order to do rotation, we need to genrate a new key and then add it in authorized key
# in private instance 

if [ -e ameer-new-key-pair1.pem ]; then

  chmod 600 copy-key.pem

  cat ameer-new-key-pair1.pem > copy-key.pem

  cat ameer-new-key-pair1.pem.pub > copy-key.pem.pub

  rm -f ameer-new-key-pair1.pem ameer-new-key-pair1.pem.pub

  chmod 400 copy-key.pem

fi

# create a key and override the pervious one

ssh-keygen -t rsa -b 4096 -f ameer-new-key-pair1.pem -N ""

cat ameer-new-key-pair1.pem.pub | ssh -o StrictHostKeyChecking=accept-new -i copy-key.pem ubuntu@"$1" "cat > ~/.ssh/authorized_keys"
