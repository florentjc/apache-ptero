#!/bin/bash
rm -rf /home/container/tmp/*
rm -rf /home/container/apache/socks/*

# Détermine la version de PHP
PHP_VERSION="${PHP_VERSION:-8.0}"

echo "⟳ Starting PHP-FPM..."
php-fpm$PHP_VERSION -c /home/container/php/php.ini --fpm-config /home/container/php/php-fpm.conf &

echo "⟳ Starting Apache..."
source /home/container/apache2/envvars
apache2 -f apache2.conf -d /home/container/apache2 -DFOREGROUND