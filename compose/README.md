# Team Edition Installation with Docker Compose

### System requirements:
- Linux or macOS
- `curl`
- [Docker](https://docs.docker.com/engine/install/ubuntu/) installed. Make sure you have chosen the right OS distro.
- [docker-compose](https://docs.docker.com/compose/install/) binary installed and added to your PATH variable. Supported versions 2.10 and above

    - **Be careful. If you install `docker-compose-plugin`, you must use the `docker compose` command instead of `docker-compose`**.
- OpenSSL.

Ensure all TCP ports from the below list are available in your network stack.
 - 80/tcp
 - 443/tcp

### Configuring and starting CloudBeaver Team cluster:

1. Change directory to `cbte`.

1. Configure CloudBeaver settings by editing the `.env` file. You must copy it from `.env.example`.

1. Configure domain name. 

    You may skip this step. In this case, the cluster will be configured for localhost.  
    Set the `CLOUDBEAVER_DOMAIN` property to the desired domain name.  
    Create DNS records for `CLOUDBEAVER_DOMAIN`. 
    
1. Configure SSL (optional). 

     If you set the *https* endpoint scheme in `.env` as value of `CLOUDBEAVER_SCHEME`, create a valid TLS certificate for a domain endpoint `CLOUDBEAVER_DOMAIN` and place it into `compose/cbte/nginx/ssl`.

    - Generate SSL certificate for a domain `CLOUDBEAVER_DOMAIN` specified in `.env` and put it to `compose/cbte/nginx/ssl/fullchain.pem` as certificate and `compose/cbte/nginx/ssl/privkey.pem` as a private key.  
    or
    - If you set up CloudBeaver in the public network, you can get a certificate from Let's Encrypt provider by starting the `install.sh` script with `le` argument. 

2. Prepare CloudBeaver environment.
    - `./install.sh`  
    or
    - `./install.sh le`  to use it with LetsEncrypt

3. Start the cluster
	- `docker-compose up -d` or `docker compose up -d` 

### Services will be accessible in the next URIs:

- CloudBeaver __CLOUDBEAVER_SCHEME__://__CLOUDBEAVER_DOMAIN__ - main CloudBeaver user interface. It will open the admin panel on the first start
- CloudBeaver __CLOUDBEAVER_SCHEME__://__CLOUDBEAVER_DOMAIN__/dc - endpoint for desktop applications

### Stopping the cluster
`docker-compose down`


### Version update procedure.

1. Change directory to `team-edition-deploy/compose/cbte`.

2. Change value of `CLOUDBEAVER_VERSION_TAG` in `.env` with a preferred version. Go to next step if tag `latest` set.

3. Pull new docker images: `docker-compose pull` or `docker compose pull`  

4. Retart cluster: `docker-compose up -d` or `docker compose up -d` 
