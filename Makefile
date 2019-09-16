docker_push = docker push $(DOCKER_TARGET_REPO)/$(2) | cat  

tagged_image_list = `docker images | grep $(BUILD_NUMBER) | cut -d" " -f1 | cat`

#we want a couple things in our tag list
#if this is a tagged git repo, we want the tag as a tag
#if it's the development branch, we want to tag it as "latest"
#if it's anything else, we use the branch
tag_list = radderone

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
	TAGSFORBRANCH=$(GIT_BRANCH); \
	if [ $(GIT_BRANCH) = "develop" ]; then \
		TAGSFORBRANCH="latest";\
	fi; \
	if [ "istaggedcheck" = "shouldgohere" ]; then \
		TAGSFORBRANCH="$$TAGSFORBRANCH tagnamehere";\
	fi;\
	for repository in $(shell docker images | grep $(BUILD_NUMBER) | cut -d" " -f1 | cat); do \
		for tagname in $$TAGSFORBRANCH $(tag_list); do \
			docker tag $$repository:$$BUILD_NUMBER $$repository:$$tagname; \
			docker push $$repository:$$tagname; \
		done \
	done
