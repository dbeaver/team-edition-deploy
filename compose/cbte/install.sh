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
		echo "Please enter: sudo su $TE_USER"
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		exit 1
	fi
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

## Check certificate exists if scheme https 
## But if Let's Encrypt arg used will pass this check
if [[ $CLOUDBEAVER_SCHEME == "https" ]] || [[ -n "$1" ]] && [[ ! "$1" == "le" ]];
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
	fi
fi

#### Untemplate compose
# create empty compose yml file 
touch docker-compose.yml
docker run --rm \
	-v $(pwd)/docker-compose.yml:/docker-compose.yml \
	-v $(pwd)/docker-compose.tmpl.yml:/docker-compose.tmpl.yml \
	-v $(pwd)/helper/compose-config-editor.py:/compose-config-editor.py \
	--env-file=.env \
	python:alpine sh -c "pip install PyYAML && python /compose-config-editor.py $1"

touch nginx/cloudbeaver.locations
docker run --rm \
    -v $(pwd)/nginx/cloudbeaver.locations.template:/cloudbeaver.locations.template \
    -v $(pwd)/nginx/cloudbeaver.locations:/cloudbeaver.locations \
    -v $(pwd)/helper/cloudbeaver-locations-editor.py:/cloudbeaver-locations-editor.py \
    --env-file=.env \
    python:alpine sh -c "python /cloudbeaver-locations-editor.py"

	########################## CERTBOT PART 
function get_le_certs() {
	echo "Start LE cert getter"
	echo "Checking email address ..."
	email_regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
	if [[ $LETSENCRYPT_CERTBOT_EMAIL =~ $email_regex ]] ; then
		echo "email address OK"
	else
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo "ERROR: email address is NOT OK."
		echo "Please change LETSENCRYPT_CERTBOT_EMAIL in .env file with your valid email"
		echo "Enter 'dbeaver-te configure' to easily open .env file."
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		exit 1
	fi

	if [[ $CLOUDBEAVER_DOMAIN != "localhost" ]] ; then
		echo "domain OK"
	else
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo "ERROR: domain is NOT OK."
		echo "Please change CLOUDBEAVER_DOMAIN in .env file with your valid domain"
		echo "Enter 'dbeaver-te configure' to easily open .env file."
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		exit 1
	fi


	domain=$CLOUDBEAVER_DOMAIN	
	rsa_key_size=4096
	data_path="./data/certbot"
	email="$LETSENCRYPT_CERTBOT_EMAIL" # Adding a valid address is strongly recommended
	staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits

	if [ -d "$data_path" ]; then
			read -p "Existing data found for $domain and replace existing certificate? (y/N) " decision
			if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
					exit
			else
					TIME=$(date +"%m-%d-%y-%T")
					BACKUP_DIR="/tmp/backup-cert-$TIME"
					mkdir $BACKUP_DIR
					mv $data_path/conf $BACKUP_DIR
					echo "Old certificates have been moved to $BACKUP_DIR"
			fi
	fi

	if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
	  echo "### Downloading recommended TLS parameters ..."
	  mkdir -p "$data_path/conf"
	  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
	  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
	  echo
	fi

	echo "### Creating dummy certificate for $domain ..."
	path="/etc/letsencrypt/live/$domain"
	mkdir -p "$data_path/conf/live/$domain"
	docker-compose run --rm --entrypoint "\
	  openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
	    -keyout '$path/privkey.pem' \
	    -out '$path/fullchain.pem' \
	    -subj '/CN=$domain'" certbot
	echo

	echo "### Starting nginx ..."
	docker-compose up --force-recreate -d nginx
	echo

	echo "### Deleting dummy certificate for $domain"
	docker-compose run --rm --entrypoint "\
	  rm -Rf /etc/letsencrypt/live/$domain && \
	  rm -Rf /etc/letsencrypt/archive/$domain && \
	  rm -Rf /etc/letsencrypt/renewal/$domain.conf" certbot
	echo

	echo "### Requesting Let's Encrypt certificate for $domain	#Join $domain args"
	domain_args="-d $domain"


	email_arg="--email $email"

	# Enable staging mode if needed
	if [ $staging != "0" ]; then staging_arg="--staging"; fi

	docker-compose run --rm --entrypoint "\
	  certbot certonly --webroot -w /var/www/certbot \
		--non-interactive \
	    $staging_arg \
	    $email_arg \
	    $domain_args \
	    --rsa-key-size $rsa_key_size \
	    --agree-tos \
	    --force-renewal" certbot
	echo

	echo "### Reloading nginx ..."
	docker-compose exec nginx nginx -s reload
	echo 

	echo "Adding crontab job"
	echo "0 */12 * * *  docker-compose exec --project-directory $(pwd) nginx nginx -s reload" | crontab -
}

if [[ -n "$1" ]] && [[ "$1" == "le" ]]; then
   echo "Prepare CloudBeaver to use Letsencrypt certs"
   get_le_certs
fi

docker-compose pull
