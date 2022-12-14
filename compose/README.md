# CloudBeaver Team Edition Install
## installation

For start to use CloudBeaver DE you need to have several dependencies:
- Linux or Mac OS
- cURL installed
- [Docker](https://docs.docker.com/engine/install/ubuntu/) installed. Make sure you have chosen the right OS distro.
- [docker-compose](https://docs.docker.com/compose/install/) binary installed and added to you PATH variable. Supported version 2.10 and above
- openssl. Presented on your OS usually

Make sure that's all TCP ports from below list is available in your network stack.
 - 80/tcp
 - 443/tcp

#### There is some steps to run CloudBeaver DE with docker-compose:

Change directory to `cbte` (`cd cbte`).  

1. Configure CloudBeaver settings by editing `.env` file. You must copy it from `.env.example` 

2. Create A dns records for `CLOUDBEAVER_DOMAIN`:

3. If you set *https* endpoint scheme in `.env` than create valid TLS certificate for a domain endpoint `CLOUDBEAVER_DOMAIN` and place it into `compose/cbte/nginx/ssl`.

    - generate SSL certificate for a domain `CLOUDBEAVER_DOMAIN` specified in `.env` and put it to `compose/cbte/nginx/ssl/fullchain.pem` as certificate and `compose/cbte/nginx/ssl/privkey.pem` as a private key.
    
    __or__

    - if you set up CloudBeaver in public network you can get certificate from LetsEncrypt provider by starting `install.sh` script with `le` argument. 


4. Prepare CloudBeaver environment.
	- `chmod +x install.sh`
	- `./install.sh`

    or

    - `./install.sh le`  to use it with LetsEncrypt

5. Start CloudBeaver
	- `docker-compose up -d`


#### Services will be accessible in next uris:

CloudBeaver https://__CLOUDBEAVER_DOMAIN__

DBeaver DC Link https://__CLOUDBEAVER_DOMAIN__/dc

RM https://__CLOUDBEAVER_DOMAIN__/rm

QM https://__CLOUDBEAVER_DOMAIN__/qm

