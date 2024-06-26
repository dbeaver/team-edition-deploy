#!/bin/bash

CERT_CSR="/C=US/ST=NY/L=NYC/O=CloudBeaver Security/OU=IT Department/CN=cloudbeaver.io"
SECRET_CERT_CSR="/C=US/ST=NY/L=NYC/O=CloudBeaver Secret /OU=IT Department/CN=cloudbeaver.io"

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

if [ ! -e ".env" ] ; then
	echo ".env file not exist." >&2
	exit 1
fi

function get_secret_cert() {
	mkdir cert
	cd cert
	mkdir private
	mkdir public
	openssl req -x509 -sha256 -nodes -days 36500 -subj "$CERT_CSR" -newkey rsa:2048 -keyout private/dc-key.key -out public/dc-cert.crt
	openssl req -x509 -sha256 -nodes -days 36500 -subj "$SECRET_CERT_CSR" -newkey rsa:2048 -keyout private/secret-key.key -out private/secret-cert.crt
	cd ..
}


if [ ! -d cert ]; then
	get_secret_cert
fi


# Get setup variables from .env file
while read -r line
do
	[[ $line =~ ^#.* ]] && continue
	[[ -z $line ]] && continue
	export "$line"
done < .env

# Set COMPOSE_PROJECT_NAME if not exist
if [ -z "$COMPOSE_PROJECT_NAME" ]; then
  CURRENT_DIR=$(basename "$PWD")
  export COMPOSE_PROJECT_NAME=$CURRENT_DIR
fi


#### Untemplate compose and configure endpoints to load balancer
# create empty compose yml file 
touch docker-compose.yml
docker run --rm \
	-v $(pwd)/docker-compose.yml:/docker-compose.yml \
	-v $(pwd)/docker-compose.tmpl.yml:/docker-compose.tmpl.yml \
	-v $(pwd)/helper/compose-config-editor.py:/compose-config-editor.py \
	-v $(pwd)/nginx/dbeaver-te.locations:/dbeaver-te.locations \
	--env-file=.env \
	python:alpine sh -c "pip install PyYAML && python /compose-config-editor.py"

docker-compose pull

## Check certificate exists if scheme https 
## But if Let's Encrypt arg used will pass this check
if [[ $CLOUDBEAVER_SCHEME == "https" ]]
then
	if [ ! -f nginx/ssl/fullchain.pem ] || [ ! -f nginx/ssl/privkey.pem ];
	then
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo "ERROR: ${CLOUDBEAVER_SCHEME} scheme can not configured."
		echo "  Certificate ./nginx/ssl/fullchain.pem" 
		echo "  or key ./nginx/ssl/privkey.pem"
		echo "  not exist. Stopped"
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		exit 1
	else
		envsubst '$CLOUDBEAVER_DOMAIN' < nginx/nginx.https.conf.template | tee nginx/nginx.https.conf
		docker-compose create
		docker run --rm -d --name temporary \
			-v "$COMPOSE_PROJECT_NAME"_nginx_ssl_data:/etc/nginx/ssl/ \
			-v "$COMPOSE_PROJECT_NAME"_nginx_conf_data:/etc/nginx/product-conf/ \
			openresty/openresty:alpine
		docker exec temporary mkdir -p /etc/nginx/ssl/live/databases.team
		docker cp ./nginx/ssl/fullchain.pem temporary:/etc/nginx/ssl/live/databases.team/fullchain.pem
		docker cp ./nginx/ssl/privkey.pem temporary:/etc/nginx/ssl/live/databases.team/privkey.pem
		docker cp ./nginx/nginx.https.conf temporary:/etc/nginx/product-conf/cloudbeaver-te.conf
		docker exec --user root temporary chown -R nobody:nogroup /etc/nginx/ssl
		docker stop temporary
	fi
fi

