#!/bin/bash

cd /home/container

# Récupérer l'IP interne Docker
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2); exit}')
export INTERNAL_IP

# Préparer la commande STARTUP
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')

echo ":/home/container$ ${MODIFIED_STARTUP}"

eval "${MODIFIED_STARTUP}"

# Laisse un shell ouvert, sans bloquer
exec bash --noprofile --norc