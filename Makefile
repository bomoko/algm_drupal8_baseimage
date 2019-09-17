SHELL := /bin/bash

docker_push = docker push $(DOCKER_TARGET_REPO)/$(2) | cat  

tagged_image_list := $(shell docker images | grep $(BUILD_NUMBER) | cut -d" " -f1 | cat)

git_tag_for_current_branch := $(shell git tag --points-at) #will be non-empty if HEAD is tagged

build: ## Build the container
	docker-compose up -d --build
	docker-compose exec cli composer install
up:
	docker-compose up -d
down:
	docker-compose down
stop:
	docker-compose stop

.PHONY: images_publish
images_publish:
	TAGSFORBRANCH=$(GIT_BRANCH); \
	if [ $(GIT_BRANCH) = "develop" ]; then \
		TAGSFORBRANCH="latest";\
	fi; \
	for repository in $(tagged_image_list); do \
		for tagname in $$TAGSFORBRANCH $(git_tag_for_current_branch); do \
			docker tag $$repository:$$BUILD_NUMBER $$repository:$$tagname; \
			docker push $$repository:$$tagname; \
		done; \
	done

.PHONY: images_remove
images_remove:
	for repository in $(tagged_image_list); do \
		docker rmi $$repository:$$BUILD_NUMBER -f; \
	done
