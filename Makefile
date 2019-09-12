build: ## Build the container
	docker-compose up -d --build
	docker-compose exec cli composer install
up:
	docker-compose up -d
down:
	docker-compose down
stop:
	docker-compose stop
