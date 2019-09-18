SHELL := /bin/bash

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

# This target is simply a test of the above
.PHONY: images_echo_variables
images_echo_variables: images_set_variables
	echo $(docker_build_tag)
	echo $(tagged_image_list)
	echo $(git_tag_for_current_branch)

# This target will build out the images, passing the correct environment vars to fill out repo and tags
.PHONY: images_build
images_build: images_set_variables
	docker network create amazeeio-network || true; \
	DOCKER_REPO=$$DOCKER_REPO BUILDTAG=$(docker_build_tag) docker-compose up -d --build; \
	docker-compose exec cli drush site-install --verbose config_installer config_installer_sync_configure_form.sync_directory=/app/config/sync/ --yes; \
  docker-compose exec cli drush cr; \
  docker-compose exec cli composer require drupal/admin_toolbar; \
  docker-compose exec cli composer require drupal/cdn; \
  docker-compose exec cli composer require drupal/password_policy; \
  docker-compose exec cli composer require drupal/pathauto; \
  docker-compose exec cli composer require drupal/ultimate_cron; \
  docker-compose exec cli composer require drupal/redis; \
  docker-compose exec cli drush en admin_toolbar cdn password_policy pathauto ultimate_cron redis -y

.PHONY: images_test
images_test: images_set_variables
	docker-compose exec cli drush status; \
	docker-compose exec cli drush status bootstrap | grep -q Successful;

# This target will iterate through all images and tags, pushing up versions of all with approriate tags
.PHONY: images_publish
images_publish: images_set_variables
	TAGSFORBRANCH=default; \
	if [ $(GIT_BRANCH) = "develop" ]; then \
		TAGSFORBRANCH="latest";\
	fi; \
	for repository in $(tagged_image_list); do \
		for tagname in $$TAGSFORBRANCH $(git_tag_for_current_branch); do \
			echo "pushing " $$repository:$$tagname; \
			docker tag $$repository:$(docker_build_tag) $$repository:$$tagname; \
			docker push $$repository:$$tagname; \
		done; \
	done

# Removes all images in this BUILD_NUMBER
.PHONY: images_remove
images_remove: images_set_variables
	docker-compose down; \
	for repository in $(tagged_image_list); do \
		docker rmi $$repository:$(docker_build_tag) -f; \
	done
