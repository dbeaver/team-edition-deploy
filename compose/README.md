# Team Edition Installation with Docker Compose

It is the simplest way to install DBeaver TE.  
All you need is a Linux machine with docker.

### System requirements:
- Linux or MacOS
- [Docker](https://docs.docker.com/engine/install/ubuntu/) installed. Make sure you have chosen the right OS distro.
- [docker-compose](https://docs.docker.com/compose/install/) binary installed and added to your PATH variable. Supported versions 2.10 and above
    - If you install `docker-compose-plugin`, you must use the `docker compose` command instead of `docker-compose`.

Ensure all TCP ports from the below list are available in your network stack.
 - 80/tcp
 - 443/tcp (for HTTPS access)

### Configuring and starting CloudBeaver Team cluster:

- `cd cbte`
- `cp .env.example .env`
- Edit `.env` file to set configuration properties
- Configure domain name (optional).
   - You may skip this step. In this case, the cluster will be configured for localhost.  
   - Set the `CLOUDBEAVER_DOMAIN` property to the desired domain name.  
   - Create DNS records for `CLOUDBEAVER_DOMAIN`.  
- Configure SSL (optional). 
   - If you set the *HTTPS* endpoint scheme in `.env` then you need to create a valid TLS certificate for a domain endpoint `CLOUDBEAVER_DOMAIN` and place it into `compose/cbte/nginx/ssl`.
   - Generate SSL certificate for a domain `CLOUDBEAVER_DOMAIN` specified in `.env` and put it to `compose/cbte/nginx/ssl/fullchain.pem` as certificate and `compose/cbte/nginx/ssl/privkey.pem` as a private key.  
   - If you set up CloudBeaver in the public network, you can get a certificate from Let's Encrypt provider by starting the `install.sh` script with `le` argument. 
- Prepare CloudBeaver environment.
   - `./install.sh` (default) or `./install.sh le` (if you use LetsEncrypt)
- Start the cluster
   - `docker-compose up -d` or `docker compose up -d` 

### Services will be accessible in the next URIs:

- CloudBeaver https://__CLOUDBEAVER_DOMAIN__ - web interface. It will open the admin panel on the first start
- CloudBeaver https://__CLOUDBEAVER_DOMAIN__/dc - endpoint for desktop applications

### Stopping the cluster
`docker-compose down`

### Version update procedure.

1. `cd compose/cbte`.
2. Change value of `CLOUDBEAVER_VERSION_TAG` in `.env` with a preferred version. Go to next step if tag `latest` set.
3. Pull new docker images: `docker-compose pull` or `docker compose pull`  
4. Restart cluster: `docker-compose up -d` or `docker compose up -d` 
