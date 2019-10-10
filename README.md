# Build and manage base images for Lagoon


## Requirements

* This system is currently configured to be deployed to Jenkins - however, since most of the build scripts are contained in Makefiles, having it run on some other CI/CD system should be trivial.
* [docker](https://docs.docker.com/install/).
* [pygmy](https://docs.amazee.io/local_docker_development/pygmy.html) `gem install pygmy` (you might need sudo for this depending on your ruby configuration)
* A docker hub repository

# Understanding the build process

There are several parts to the build process. All of the major build steps are represented in the Makefile which means that most can be tested locally (this is important when building new versions of the base image)

### Makefile and build assumptions

If you're planning on running this locally (or are setting up a build process on some automation platform) there are some minimum environment variables that need to be present to build at all

Minimally you'll need to ensure that you set
* BUILD_NUMBER: This is used in tagging the images being built - in Jenkins it's provided by default.
* DOCKER_REPO: Like BUILD_NUMBER, this is used in tagging images
* GIT_BRANCH: is used primarily to tag built images that are pushed to the docker repo


Practically, this means that if you're running any of the make targets on your local machine
you'll want to ensure that these are available in the environment - even if this is just setting them like so:

`GIT_BRANCH=example_branch_name DOCKER_REPO=your_docker_repo_here BUILD_NUMBER=<some_integer> make images_remove`

### Makefile targets

The most important targets are the following

* images_build : Will, given the environment variables, build and tag the images for publication
* images_publish : pushes built images to a docker repo
* images_start : Will start the images for testing, etc.
* images_test: Runs basic tests against images 
* images_remove: removes previously build images, given the build environment variables

## Example workflow for building a new release

There are two parts to building a new release. The first part requires human intervention - this would be, for example,
adding a new module to the base image (via the composer.true.json file) and tagging the commit.


If we wanted to add a new module to the base image, assuming that you have pulled the base image down on to your local machine, the process would look something like this:

`COMPOSER=composer.true.json composer require drupal/lagoon_logs --no-update`

followed by

`GIT_BRANCH=tester DOCKER_REPO=algmprivsecops BUILD_NUMBER=1 make semilock_build`

This second step will go through the motions of generating the semilock file.

You should, then, see several files ready to be committed to the repo - your composer.true.json, and composer.json (the semilock file).


### Understanding how Images are tagged

There can be multiple tags per image.

Any change pushed to the `master` branch will result in a build that is tagged as `latest` for images.

Further, if there are any tags on the commit the images are being built from, this will result in a tagged image being
 pushed to the docker hub.

## How do derived images relate to this base image

All derived images should pull in the composer.lock file (via packagist or github) so that they are delivered the most
recent versions of the base packages.

Further, at the derived image, there is a call to the script `/build/pre_composer` which can be used by the base image to
run scripts/updates/etc. downstream in the derived images. For instance, by default, it should run when any package is
updated or installed at the derived image, the `pre_composer` script will then update the base image package.

## Understanding the semilock file

One of the challenges with allowing derived images to add their own modules while
simultaneously having a "base" with fixed module versions (Drupal core, some contrib modules etc.)
is that enforcing the base image's versions at the derived image's build time becomes difficult.

The way we've approached this is to follow the example of Webflo's [drupal-core-strict](https://github.com/webflo/drupal-core-strict) project,
which produces composer.json files with _exact_ versions of modules - this allows a composer.json file
to act as if it was a lock file. This kind of composer.json file with fixed module versions is what we've
called a semilock file.

In order to be able to generate a composer.json semilock file, we need an _actual_ composer.json file to build from.
In our base image we keep the loosely versioned composer.json in the file composer.true.json - this is the canonical
composer.json and is the file that should be edited when, for instance, new modules are required to be added, etc.

## FAQ

### How can I apply patches to downloaded modules?

If you need to apply patches (depending on the project being modified, a pull
request is often a better solution), you can do so with the
[composer-patches](https://github.com/cweagans/composer-patches) plugin.

To add a patch to drupal module foobar insert the patches section in the extra
section of composer.json:
```json
"extra": {
    "patches": {
        "drupal/foobar": {
            "Patch description": "URL to patch"
        }
    }
}
```

## Acknowledgements
The following draws heavily (and, in fact, is a "fork" of) [Denpal](https://github.com/dennisarslan/denpal).
It is based on the [original Drupal Composer Template](https://github.com/drupal-composer/drupal-project), but includes everything necessary to run on amazee.io (either the local development environment or on amazee.io servers.)
