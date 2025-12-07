#!/bin/bash

# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e ":/home/container$ ${MODIFIED_STARTUP}"

echo "♻️ Clearing temporary files and cache..."
rm -rf /home/container/tmp/* 2>/dev/null || true
rm -rf /home/container/apache/socks/* 2>/dev/null || true

PHP_VERSION_FULL=$(php -v | head -1 | cut -d' ' -f2 | cut -d- -f1)
PHP_VERSION_SMALL=${PHP_VERSION_FULL%.*}
echo "⟳ Starting PHP-FPM (version $PHP_VERSION_FULL)..."
php-fpm$PHP_VERSION_SMALL -c /home/container/php/php.ini --fpm-config /home/container/php/php-fpm.conf &
PHP_FPM_PID=$!
if [ $? -ne 0 ]; then
    echo "❌ Failed to start PHP-FPM"
    exit 1
fi

echo "⟳ Starting Apache..."
source /home/container/apache2/envvars
apache2 -f apache2.conf -d /home/container/apache2 &
APACHE_PID=$!
if [ $? -ne 0 ]; then
    echo "❌ Failed to start Apache"
    exit 1
fi

if [ -n "$MODIFIED_STARTUP" ] && [ "$MODIFIED_STARTUP" != "$STARTUP" ]; then
    eval ${MODIFIED_STARTUP} &
    STARTUP_PID=$!
fi

if [ -f "/shell.sh" ]; then
    echo "⟳ Starting custom shell..."
    exec /shell.sh
fi

wait $PHP_FPM_PID $APACHE_PID ${STARTUP_PID:-}