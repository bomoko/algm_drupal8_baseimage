#!/bin/sh
docker-compose exec -T cli composer install;
docker-compose exec -T cli drush -r /app/web site-install --verbose config_installer config_installer_sync_configure_form.sync_directory=/app/config/sync/ --yes;
docker-compose exec -T cli drush cr;
docker-compose exec -T cli ./build/check_installation.sh;
