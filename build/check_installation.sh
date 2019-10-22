#!/bin/sh
drush status
if ! drush -r /app/web status --fields=bootstrap | grep -q "Successful"; then
	echo "Drupal Bootstrapping failed"
	exit 1
fi
echo "Drupal Bootstrapped successfully"
