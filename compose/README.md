# CloudBeaver Team Edition Install
## installation

System requirements:
- Linux or Mac OS
- cURL installed
- [Docker](https://docs.docker.com/engine/install/ubuntu/) installed. Make sure you have chosen the right OS distro.
- [docker-compose](https://docs.docker.com/compose/install/) binary installed and added to you PATH variable. Supported version 2.10 and above
    
    - **Be careful. If you install `docker-compose-plugin` you must use `docker compose` command instead of `docker-compose`**
- openssl. Presented on your OS usually

Make sure that's all TCP ports from below list is available in your network stack.
 - 80/tcp
 - 443/tcp

### Configuring and starting CloudBeaver Team cluster:

Change directory to `cbte`.  

1. Configure CloudBeaver settings by editing `.env` file. You must copy it from `.env.example` 

2. Configure domain name (optional). 

    You may skip this step, in this case cluster will be configured for localhost.  
    Set CLOUDBEAVER_DOMAIN property to desired domain name.  
    Create A dns records for `CLOUDBEAVER_DOMAIN`. 
    
3. Configure SSL (optional). 

     If you set *https* endpoint scheme in `.env` than create valid TLS certificate for a domain endpoint `CLOUDBEAVER_DOMAIN` and place it into `compose/cbte/nginx/ssl`.

    - generate SSL certificate for a domain `CLOUDBEAVER_DOMAIN` specified in `.env` and put it to `compose/cbte/nginx/ssl/fullchain.pem` as certificate and `compose/cbte/nginx/ssl/privkey.pem` as a private key.  
    or
    - if you set up CloudBeaver in public network you can get certificate from LetsEncrypt provider by starting `install.sh` script with `le` argument. 

4. Prepare CloudBeaver environment.
    - `./install.sh`  
    or
    - `./install.sh le`  to use it with LetsEncrypt

5. Start the cluster
	- `docker-compose up -d` or `docker compose up -d` 

### Services will be accessible in next uris:

- CloudBeaver https://__CLOUDBEAVER_DOMAIN__ - main CloudBeaver user interface. It will open admin panel on first start
- CloudBeaver https://__CLOUDBEAVER_DOMAIN__/dc - endpoint for desktop applications

### Stopping the cluster
`docker-compose down`
      
