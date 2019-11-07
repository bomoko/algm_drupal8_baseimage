SHELL := /bin/bash -x

# step to call before running any of the following, ensures that requisite environment variables for build are set
.PHONY: images_check_env
images_check_env:
ifndef BUILD_NUMBER
	$(error BUILD_NUMBER is undefined - cannot proceed with step)
endif
ifndef DOCKER_REPO
	$(error DOCKER_REPO is undefined - cannot proceed with step)
endif
ifndef GIT_BRANCH
	$(error GIT_BRANCH is undefined - cannot proceed with step)
endif

# here we set the variables that are used in the building, pushing, and removing of images
.PHONY: images_set_variables
images_set_variables: images_check_env
	$(eval docker_build_tag := "buildtag_$(BUILD_NUMBER)")
	$(eval tagged_image_list := $(shell docker images | grep "$(docker_build_tag)" | cut -d" " -f1 | cat))
	$(eval git_tag_for_current_branch := $(shell git tag --points-at)) #will be non-empty if HEAD is tagged
	$(eval git_latest_tag := $(shell git tag | sort -V -f | grep -E "^[v|V][0-9]+\.[0-9]+\.[0-9]+$$" | tail -n 1))

# Set some targets for the build step.
.PHONY: images_set_build_variables
images_set_build_variables: images_check_env images_set_variables
	$(eval docker_networks := $(shell docker network inspect amazeeio-network | grep -o '\"Name\": \"[^\"]*' | sed 's/^.*: //' | sed 's/"//g' | cat))
	$(eval has_io_network := $(shell echo $(docker_networks) | tr ' ' '\n' | grep -c "amazeeio-network"))

# This target will build out the images, passing the correct environment vars to fill out repo and tags
.PHONY: images_build
images_build: images_set_build_variables
	DOCKER_REPO=$$DOCKER_REPO BUILDTAG=$(docker_build_tag) docker-compose build

.PHONY: images_start_network
images_start_network: images_set_build_variables
	if [ "$(has_io_network)" = 0 ]; then \
		DOCKER_REPO=$$DOCKER_REPO BUILDTAG=$(docker_build_tag) docker network create amazeeio-network; \
	fi;

.PHONY: images_start
images_start: images_set_build_variables images_start_network
	DOCKER_REPO=$$DOCKER_REPO BUILDTAG=$(docker_build_tag) docker-compose config -q; \
	DOCKER_REPO=$$DOCKER_REPO BUILDTAG=$(docker_build_tag) docker-compose up -d;

.PHONY: images_test
images_test: images_start
	#DOCKER_REPO=$$DOCKER_REPO BUILDTAG=$(docker_build_tag) docker-compose exec -T cli composer install; \
	#DOCKER_REPO=$$DOCKER_REPO BUILDTAG=$(docker_build_tag) docker-compose exec -T cli drush -r /app/web site-install --verbose config_installer config_installer_sync_configure_form.sync_directory=/app/config/sync/ --yes; \
	#DOCKER_REPO=$$DOCKER_REPO BUILDTAG=$(docker_build_tag) docker-compose exec -T cli drush cr; \
	#DOCKER_REPO=$$DOCKER_REPO BUILDTAG=$(docker_build_tag) docker-compose exec -T cli ./build/check_installation.sh;

# This target will iterate through all images and tags, pushing up versions of all with approriate tags
.PHONY: images_publish
images_publish: images_set_build_variables
	TAGSFORBRANCH=""; \
	if [ $(GIT_BRANCH) = "master" ]; then \
		TAGSFORBRANCH="master";\
	fi; \
	if [ $(GIT_BRANCH) = "develop" ]; then \
		TAGSFORBRANCH="develop";\
	fi; \
	if [ "$(git_latest_tag)" = "$(git_tag_for_current_branch)" ]; then TAGSFORBRANCH="$(TAGSFORBRANCH) latest"; fi; \
	echo $$TAGSFORBRANCH; \
	for repository in $(tagged_image_list); do \
		for tagname in $$TAGSFORBRANCH $(git_tag_for_current_branch); do \
			echo "pushing " $$repository:$$tagname; \
			docker tag $$repository:$(docker_build_tag) $$repository:$$tagname; \
			docker push $$repository:$$tagname; \
		done; \
	done

# Removes all images in this BUILD_NUMBER
.PHONY: images_remove
images_remove: images_set_build_variables
	docker-compose down; \
	for repository in $(tagged_image_list); do \
		docker rmi $$repository:$(docker_build_tag) -f; \
	done


## Targets for building the composer semilock file
.PHONY: semilock_build
semilock_build: images_build images_start
	docker-compose exec cli /app/build/build_semilock
