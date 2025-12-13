#!/bin/sh
set -e

# Ensure storage directories exist
mkdir -p /var/www/html/storage/uploads
mkdir -p /var/www/html/storage/results

# Ensure permissions (www-data is usually uid 82 on alpine or 33 on debian, check dockerfile base)
# In php:8.2-fpm-alpine default user is www-data (82)
chown -R www-data:www-data /var/www/html/storage

# If database doesn't exist, create an empty file so it can be owned by ww-data
if [ ! -f /var/www/html/storage/database.sqlite ]; then
    touch /var/www/html/storage/database.sqlite
    chown www-data:www-data /var/www/html/storage/database.sqlite
fi

# Run the CMD
exec "$@"
