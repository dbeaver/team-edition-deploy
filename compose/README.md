# Team Edition Installation with Docker Compose

It is the simplest way to install DBeaver Team Edition.  
All you need is a Linux machine with docker.

- [System requirements](#system-requirements)
- [Configuring and starting Team Edition cluster](#configuring-and-starting-team-edition-cluster)
- [Using external DB](#using-external-db)
- [Team Edition manager](#team-edition-manager)
- [Version update procedure](#version-update-procedure)
- [Custom image source](#custom-image-source)
- [Service scaling](#service-scaling)
- [Prerequisites for Podman](#podman-prerequisites)
- [Prerequisites for RedHat](#redhat-prerequisites)

## System requirements


- Minimum 16GB RAM
- Minimum 50GB storage, > 100GB recommended
- Ubuntu is recommended, but it also works on other Linux distributions, macOS, and Windows
- [Docker](https://docs.docker.com/engine/install/ubuntu/) installed. Make sure you have chosen the right OS distro.
- [docker-compose](https://docs.docker.com/compose/install/) binary installed and added to your PATH variable. Supported versions 2.10 and above
    - If you install `docker-compose-plugin`, you must use the `docker compose` command instead of `docker-compose`.

Ensure all TCP ports from the below list are available in your network stack.
 - 80/tcp
 - 443/tcp (for HTTPS access)

 > Note:
 > - For deployment with Podman please ensure made the [following steps](#podman-prerequisites) before configuring the Team Edition cluster.
> - If you want to deploy Team Edition on RedHat, please ensure made the [following steps](#redhat-prerequisites) before configuring the cluster.


## Configuring and starting Team Edition cluster

1. Clone Git repository
  To get started, clone the Git repository to your local machine by running the following command in your terminal:
    ```
    git clone https://github.com/dbeaver/team-edition-deploy.git
    ```
2. Open configuration file:
    - Navigate to `team-edition-deploy/compose/cbte`
    - Copy `.env.example` to `.env`
    - Edit `.env` file to set configuration properties
3. Configure domain name (optional):
   - You may skip this step. In this case, the cluster will be configured for `localhost`.  
   - Set the `CLOUDBEAVER_DOMAIN` property to the desired domain name.  
   - Create DNS records for `CLOUDBEAVER_DOMAIN`.  
4. [Configure SSL](../SSL/README.md#ssl-certificate-configuration)
5. Start the cluster:
   - `docker-compose up -d` or `docker compose up -d`  

### Services will be accessible in the next URIs

- https://__CLOUDBEAVER_DOMAIN__ - web interface. It will open the admin panel on the first start
- https://__CLOUDBEAVER_DOMAIN__/dc - endpoint for desktop applications

### Stopping the cluster
`docker-compose down`

### Encryption keys

After running `docker compose up -d`, Encryption keys for internal services will be generated and put in the `team-edition-deploy/compose/cbte/cert`.

**Important:** Encryption keys are used to decrypt user data. If you lose them, all data in your cluster will be unavailable. Please backup them and keep in a secure storage.

#### Encryption keys backup

To ensure the safety and integrity of your data, it is recommended to create a backup. Please follow these steps:

1. Create an archive of the following directory: `team-edition-deploy/compose/cbte/cert`.  
2. Copy the archived directory from your Team Edition server to your private environment.

## Using external DB

By default, Team Edition stores all data in an internal PostgreSQL database. If you want to use it, skip this step.

If you want to use another database on your side, you can do it according to these instructions.

1. Navigate to `team-edition-deploy/compose/cbte` folder, and open `.env.example` file.
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

#### PostgreSQL update procedure

If you want to update the internal PostgreSQL to version 17, follow these steps:

1. Navigate to `team-edition-deploy/compose/cbte`
2. Stop the cluster: `docker-compose down` or `docker compose down`
3. Run the update script: `./cloudbeaver-postgres-upgrade.sh`
4. Update the PostgreSQL version in your Docker Compose file to 17 as shown

```
${IMAGE_SOURCE:-dbeaver}/cloudbeaver-postgres:17
```
5. Restart the cluster: `docker-compose up -d` or `docker compose up -d`

## Team Edition manager

This repository includes a script manager that facilitates managing various tasks when using the Team Edition cluster. This is optional, you can use the usual docker compose commands instead.

Manager installation:

1. Navigate to the `team-edition-deploy/manager` directory.
2. Run the `./install-manager.sh` script.

Now you can use `dbeaver-te` command to start manager.

For detailed instructions on how to use the script manager, refer to [manager doucmentation](../manager/README.md).


## Version update procedure

1. Navigate to `team-edition-deploy/compose/cbte`
2. Change value of `CLOUDBEAVER_VERSION_TAG` in `.env` with a preferred version. Go to next step if tag `latest` is set.
3. Pull new docker images: `docker-compose pull` or `docker compose pull`  
4. Restart cluster: `docker-compose up -d` or `docker compose up -d`


### Version update from 24.0.0 or earlier

There are significant deployment changes in version 24.1.0.

So if you want to update Team Edition:
- from version 24.0.0 or early
- to version 24.1.0 or later

you have to follow these steps:

#### Step 1. Get last changes and open configuration

- If you deploy Team Edition with docker-compose:
    1. Navigate to `team-edition-deploy`
    2. Run command `git checkout --force %version%`
    3. Open the `.env` file located at `team-edition-deploy/compose/cbte/`
- If you use for deployment preconfigured AMI, simply run this command: `dbeaver-te configure`

#### Step2. Add the following environment variables:

```
REPLICA_COUNT_TE=1
REPLICA_COUNT_TM=1
REPLICA_COUNT_QM=1
REPLICA_COUNT_RM=1
IMAGE_SOURCE=dbeaver
```

and change version tag to

```
CLOUDBEAVER_VERSION_TAG=24.2.0
```

#### Step 3. Restart cluster

1. Stop your cluster:
- run `dbeaver-te stop` if you use script manager
- or navigate to the directory `team-edition-deploy/compose/cbte` and run `docker-compose down`
2. Start your cluster:
- run `dbeaver-te start` if you use script manager
- or navigate to the directory `team-edition-deploy/compose/cbte` and run `docker-compose up -d`  

### Bug fixes in version update

If you experience errors when updating your cluster, like that:
```
Error response from daemon: Could not find the file /etc/nginx/product-base in container temporary
```

Follow the next steps:


1. Stop your cluster:
- run `dbeaver-te stop` if you use script manager
- or navigate to the directory `team-edition-deploy/compose/cbte` and run `docker-compose down`

2. Remove nginx config volume:
```
docker volume rm cbte_nginx_conf_data
```
3. Make sure you have given enough permission to your certificates so that they can be read and copied.

4. Start your cluster:
- run `dbeaver-te start` if you use script manager
- or navigate to the directory `team-edition-deploy/compose/cbte` and run `docker-compose up -d`


## Custom image source

To configure the image source into which you cloned our images for the cluster, follow these steps:

- Open the `.env` file located at `team-edition-deploy/compose/cbte/` or use the command `dbeaver-te configure`
- Change the value of the `IMAGE_SOURCE` variable to the address of your registry. By default, it is set to `dbeaver`, which points to our DockerHub.

```
IMAGE_SOURCE=dbeaver
```

## Service scaling

To scale your service within the cluster, follow these steps:

- Open the `.env` file located at `team-edition-deploy/compose/cbte/` or use command `dbeaver-te configure`
- Modify the following environment variables to set the desired number of instances for each service:

```
REPLICA_COUNT_TE=1
REPLICA_COUNT_TM=1
REPLICA_COUNT_QM=1
REPLICA_COUNT_RM=1
```

Adjust the values as needed to scale each service accordingly.


## Prerequisites

### Podman prerequisites

To configure Team Edition with Podman, follow these steps:

1. Run the following commands as user `root` before [Configuring and starting Team Edition cluster](#configuring-and-starting-team-edition-cluster):

  - ```loginctl enable-linger 1000```
  - ```echo 'net.ipv4.ip_unprivileged_port_start=80' >> /etc/sysctl.conf```
  - ```sysctl -p```

2. On the step 3 and 4 of [Configuring and starting Team Edition cluster](#configuring-and-starting-team-edition-cluster) use `podman-compose` tool instead of `docker-compose`

3. On step 4 define compose file name:
```
podman-compose -f podman-compose.yml up -d
```
or replace `docker-compose.yml` with `podman-compose.yml` and use `podman-compose` without compose project definition.

## RedHat prerequisites

To configure Team Edition on RedHat, run these commands as user `root` before [Configuring and starting Team Edition cluster](#configuring-and-starting-team-edition-cluster):

```
loginctl enable-linger 1000
echo 'net.ipv4.ip_unprivileged_port_start=80' >> /etc/sysctl.conf
sysctl -p
setsebool -P httpd_can_network_relay 1
setsebool -P httpd_can_network_connect 1
semanage permissive -a httpd_t
```
