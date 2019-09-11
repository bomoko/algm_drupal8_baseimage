docker-compose config -q
docker network prune -f && docker network inspect amazeeio-network >/dev/null || docker network create amazeeio-network
docker-compose up -d --build "$@"
#docker-compose exec test dockerize -wait tcp://mariadb:3306 -timeout 1m
#docker-compose exec -T test drush si -y govcms --site-name="Welcome to GovCMS" "$@"
#docker-compose exec -T cli drush status
#docker-compose exec -T cli drush -y sql-sync @master @self
