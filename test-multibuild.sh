docker network prune -f && docker network inspect amazeeio-network >/dev/null || docker network create amazeeio-network
COMPOSE_PROJECT_NAME=denpal docker-compose down
COMPOSE_PROJECT_NAME=denpal docker-compose up -d --build "$@"
