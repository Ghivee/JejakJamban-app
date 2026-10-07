#!/bin/sh
set -eu

php artisan migrate --force
exec apache2-foreground
