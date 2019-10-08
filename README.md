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

# TODO: remove stuff that doesn't make sense below this ...


## Local environment setup

1. Checkout project repo and confirm the path is in docker's file sharing config - https://docs.docker.com/docker-for-mac/#file-sharing

```
git clone https://github.com/amazeeio/drupal-example.git drupal8-lagoon && cd $_
```

2. Make sure you don't have anything running on port 80 on the host machine (like a web server) then run `pygmy up`

3. Build and start the build images

```
docker-compose up -d
docker-compose exec cli composer install
```

4. Visit the new site @ `http://drupal-example.docker.amazee.io`

* If any steps fail you're safe to rerun from any point,
starting again from the beginning will just reconfirm the changes.

## What does the template do?

When installing the given `composer.json` some tasks are taken care of:

* Drupal will be installed in the `web`-directory.
* Autoloader is implemented to use the generated composer autoloader in `vendor/autoload.php`,
  instead of the one provided by Drupal (`web/vendor/autoload.php`).
* Modules (packages of type `drupal-module`) will be placed in `web/modules/contrib/`
* Themes (packages of type `drupal-theme`) will be placed in `web/themes/contrib/`
* Profiles (packages of type `drupal-profile`) will be placed in `web/profiles/contrib/`
* Creates the `web/sites/default/files`-directory.
* Latest version of drush is installed locally for use at `vendor/bin/drush`.
* Latest version of [Drupal Console](http://www.drupalconsole.com) is installed locally for use at `vendor/bin/drupal`.

## Updating Drupal Core

This project will attempt to keep all of your Drupal Core files up-to-date; the
project [drupal-composer/drupal-scaffold](https://github.com/drupal-composer/drupal-scaffold)
is used to ensure that your scaffold files are updated every time drupal/core is
updated. If you customize any of the "scaffolding" files (commonly .htaccess),
you may need to merge conflicts if any of your modified files are updated in a
new release of Drupal core.

Follow the steps below to update your core files.

1. Run `composer update drupal/core --with-dependencies` to update Drupal Core and its dependencies.
1. Run `git diff` to determine if any of the scaffolding files have changed.
   Review the files for any changes and restore any customizations to
  `.htaccess` or `robots.txt`.
1. Commit everything all together in a single commit, so `web` will remain in
   sync with the `core` when checking out branches or running `git bisect`.
1. In the event that there are non-trivial conflicts in step 2, you may wish
   to perform these steps on a separate branch, and use `git merge` to combine the
   updated core files with your customized files. This facilitates the use
   of a [three-way merge tool such as kdiff3](http://www.gitshah.com/2010/12/how-to-setup-kdiff-as-diff-tool-for-git.html). This setup is not necessary if your changes are simple;
   keeping all of your modifications at the beginning or end of the file is a
   good strategy to keep merges easy.

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
