#!/bin/bash
rm -rf /home/container/tmp/*
PHP_VERSION=$(cat "/home/container/php_version.txt")

# Démarrer PHP-FPM
echo "⟳ Starting PHP-FPM..."
php-fpm$PHP_VERSION -c /home/container/php/php.ini --fpm-config /home/container/php/php-fpm.conf --daemonize > /dev/null 2>&1

# Démarrer Apache
echo "⟳ Starting Apache..."
echo "✓ Services successfully launched"