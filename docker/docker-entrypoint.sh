#!/bin/sh
set -e

# Apache gets grumpy about PID files pre-existing
rm -f /usr/local/apache2/logs/httpd.pid
chown -R www-data:www-data /var/www

exec /usr/sbin/apache2ctl -D FOREGROUND