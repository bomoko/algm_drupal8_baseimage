docker_push = docker push $(DOCKER_TARGET_REPO)/$(2) | cat  

tagged_image_list = `docker images | grep $(BUILD_NUMBER) | cut -d" " -f1 | cat`

tag_list = development latest

build: ## Build the container
	docker-compose up -d --build
	docker-compose exec cli composer install
up:
	docker-compose up -d
down:
	docker-compose down
stop:
	docker-compose stop

images_publish:
	$(call docker_tag_and_push, drupal8_php,bomoko:maketest)

images_list:
	for repository in $(shell docker images | grep $(BUILD_NUMBER) | cut -d" " -f1 | cat); do \
		for tagname in $(tag_list); do \
		docker tag $$repository:$$BUILD_NUMBER $$repository:$$tagname \
		#docker push $$repository:$$tagname; \
		done \
	done
