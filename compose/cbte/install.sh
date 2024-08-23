#!/bin/bash

shopt -s expand_aliases
set -e

if [ -f "/etc/systemd/system/dbeaver-team-server.service" ]; then
	TE_USER=$(grep -Po 'User=\K.*' /etc/systemd/system/dbeaver-team-server.service)
	if [[ "$(whoami)" != "$TE_USER" ]] ; then
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo "ERROR: Wrong user"
		echo "Please enter: sudo su - $TE_USER"
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		exit 1
	fi
else
	INSTALL_DIR="$HOME/bin"
	mkdir -p "$INSTALL_DIR"

	cp "../../manager/dbeaver-te" "$INSTALL_DIR/"

	chmod +x "$INSTALL_DIR/dbeaver-te"

	if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
		echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> ~/.bashrc
		source ~/.bashrc
	fi

	CURRENT_DIR=$(pwd)
	sed -i "s|/opt/dbeaver-team-server/team-edition-deploy/compose/cbte/|$CURRENT_DIR/|g" "$INSTALL_DIR/dbeaver-te"
fi

## Flag to replace postgres pass

### Check docker installed
if ! [ -x "$(command -v docker)" ]; then
	echo 'Error: docker is not installed.' >&2
	exit 1
fi

#### Ckech user can use docker 
if ! docker ps  > /dev/null 2>&1; then
	echo "You need to add $(whoami) user in to docker group." >&2
	echo "Example: sudo gpasswd -a $(whoami) docker" >&2
	echo "After that you must reload session - logout, login" >&2
	exit 1
fi


if docker compose > /dev/null 2>&1; then
	echo "Docker compose plugin temporary aliased in to docker-compose"
	alias docker-compose="docker compose"
elif docker-compose > /dev/null 2>&1; then  
	echo "Found docker-compose binary. "
else 
	echo "docker compose plugin or docker-compose binary not installed."
	echo "Go to Docker Compose Install Docks: https://docs.docker.com/compose/install/" 
	exit 1
fi

compose_ver=`docker-compose version --short`
if [ "${compose_ver%%.*}" -ge 2 ]; then
	echo "compose is actual"
else
	echo "To use this app, you must use docker-compose version 2.x or later."
	exit 1
fi

#### Untemplate compose and configure endpoints to load balancer
# create empty compose yml file 
docker run --rm \
	-v $(pwd)/docker-compose.yml:/docker-compose.yml \
	-v $(pwd)/helper/compose-config-editor.py:/compose-config-editor.py \
	--env-file=.env \
	python:alpine sh -c "pip install PyYAML && python /compose-config-editor.py"

docker-compose pull
