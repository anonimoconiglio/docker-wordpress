#!/usr/bin/env bash

# MIT © Santiago Greco - fsgreco@hey.com
# This script aim to install the same plugins you have on production on your local wp container
# It do so by fetching (or building) a list of instructions to install those plugins.
# When it has the instructions it launches an instance of wp-cli via docker, where it executes them.
#
# The instructions for wp-cli will be already setted thanks to `generate-plugins-script.sh`
# For more context and information please consult the documentation of the entire project:
# docker-wordpress - https://github.com/fsgreco/docker-wordpress#sync-plugins


INSTALL_SCRIPT="./helpers/install-plugins.sh"
if [ ! -f $INSTALL_SCRIPT ]; then

	source ./helpers/generate-plugin-script.sh
	generate_plugin_list
	if [ "$1" = "test" ];then echo "Created $INSTALL_SCRIPT" && exit 0; fi

else 
	echo "Skipping fetching plugins from production - $INSTALL_SCRIPT already exist."
fi

echo "Running docker instance to install plugins inside the container..."

docker run -it --rm \
    --volumes-from ${1:-'wp-site'} \
    --network container:${1:-'wp-site'} \
		-e WORDPRESS_DB_HOST=db:3306 \
    -e WORDPRESS_DB_USER=wp_user \
    -e WORDPRESS_DB_PASSWORD=wp_pass \
    -e WORDPRESS_DB_NAME=wp_wordpress \
    --mount type=bind,source="$(pwd)"/helpers/install-plugins.sh,target=/var/www/html/install-plugins.sh \
    --user=${2:-1000}:${3:-1000} \
    wordpress:cli-php7.4 /var/www/html/install-plugins.sh
