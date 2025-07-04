#!/bin/bash
sleep 1

cd /home/container

# Récupère l'adresse IP interne du conteneur Docker
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Remplace les variables {{VAR}} par ${VAR} dans la commande STARTUP
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Lance la commande startup si elle existe
if [ -n "$MODIFIED_STARTUP" ]; then
    eval "${MODIFIED_STARTUP}"
fi

# Démarre PHP-FPM en arrière-plan (sans --daemonize)
PHP_VERSION="${PHP_VERSION:-8.0}"
php-fpm$PHP_VERSION -c /home/container/php/php.ini --fpm-config /home/container/php/php-fpm.conf &

# Démarre Apache en avant-plan (bloquant)
source /home/container/apache2/envvars
exec apache2 -f apache2.conf -d /home/container/apache2 -DFOREGROUND
