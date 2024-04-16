# Team Edition Installation with Docker Compose

It is the simplest way to install DBeaver Team Edition.  
All you need is a Linux machine with docker.

### System requirements

- Minimum 16GB RAM
- Minimum 50GB storage, > 100GB recommended
- Ubuntu recommended
- [Docker](https://docs.docker.com/engine/install/ubuntu/) installed. Make sure you have chosen the right OS distro.
- [docker-compose](https://docs.docker.com/compose/install/) binary installed and added to your PATH variable. Supported versions 2.10 and above
    - If you install `docker-compose-plugin`, you must use the `docker compose` command instead of `docker-compose`.

Ensure all TCP ports from the below list are available in your network stack.
 - 80/tcp
 - 443/tcp (for HTTPS access)


### Using external DB

By default, Team Edition stores all data in an internal PostgreSQL database. If you want to use it, skip this step.

If you want to use another database on your side, you can do it according to these instructions.

1. Go to the `compose/cbte` folder, and open `.env.example` file.
2. Change `USE_EXTERNAL_DB` to `true` value.
3. Change `CLOUDBEAVER_DB_DRIVER` to driver for a database you want to use, for example: `postgres-jdbc`/`mysql8`/`oracle_thin`
4. Enter the authentication data for your database in the fields `CLOUDBEAVER_DB_URL` `CLOUDBEAVER_DB_USER` `CLOUDBEAVER_DB_PASSWORD`


#### Configure Oracle database

   Connect to your Oracle database and run:
```
   CREATE USER DC;  
   GRANT UNLIMITED TABLESPACE TO DC;  
   CREATE USER TM;  
   GRANT UNLIMITED TABLESPACE TO TM;  
   CREATE USER QM;  
   GRANT UNLIMITED TABLESPACE TO QM;  
```

#### Configure Postgres database  

   Connect to your Postgres database and run:
```
   CREATE SCHEMA IF NOT EXISTS dc;
   CREATE SCHEMA IF NOT EXISTS qm;
   CREATE SCHEMA IF NOT EXISTS tm;
```

#### Configure MySQL database

   Connect to your MySQL database and run:
```
   CREATE SCHEMA IF NOT EXISTS dc;
   CREATE SCHEMA IF NOT EXISTS qm;
   CREATE SCHEMA IF NOT EXISTS tm;
```

### Configuring and starting Team Edition cluster

1. Open configuration file
    - `cd compose/cbte`
    - `cp .env.example .env`
    - Edit `.env` file to set configuration properties
2. Configure domain name (optional)
   - You may skip this step. In this case, the cluster will be configured for localhost.  
   - Set the `CLOUDBEAVER_DOMAIN` property to the desired domain name.  
   - Create DNS records for `CLOUDBEAVER_DOMAIN`.  
3. Configure SSL (optional)
   - If you set the *HTTPS* endpoint scheme in `.env` then you need to create a valid TLS certificate for a domain endpoint `CLOUDBEAVER_DOMAIN` and place it into `compose/cbte/nginx/ssl`.
   - Generate SSL certificate for a domain `CLOUDBEAVER_DOMAIN` specified in `.env` and put it to `compose/cbte/nginx/ssl/fullchain.pem` as certificate and `compose/cbte/nginx/ssl/privkey.pem` as a private key.  
   - If you set up Team Edition in the public network, you can get a certificate from Let's Encrypt provider by starting the `install.sh` script with `le` argument.
3. Prepare Team Edition environment
   - `./install.sh` (default) or `./install.sh le` (if you use LetsEncrypt)
4. Start the cluster
   - `docker-compose up -d` or `docker compose up -d`

### Services will be accessible in the next URIs

- https://__CLOUDBEAVER_DOMAIN__ - web interface. It will open the admin panel on the first start
- https://__CLOUDBEAVER_DOMAIN__/dc - endpoint for desktop applications

### Stopping the cluster
`docker-compose down`

### Version update procedure

1. `cd compose/cbte`
2. Change value of `CLOUDBEAVER_VERSION_TAG` in `.env` with a preferred version. Go to next step if tag `latest` is set.
3. Pull new docker images: `docker-compose pull` or `docker compose pull`  
4. Restart cluster: `docker-compose up -d` or `docker compose up -d`
