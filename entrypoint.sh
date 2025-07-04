#!/bin/bash
sleep 1

cd /home/container

# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e ":/home/container$ ${MODIFIED_STARTUP}"

# Démarre Apache en avant-plan (bloquant)
source /home/container/apache2/envvars
exec apache2 -f apache2.conf -d /home/container/apache2 -DFOREGROUND