# Team Edition Installation with Docker Compose or Podman Compose

DBeaver Team Edition is a containerized application that can be deployed using Docker Compose or Podman Compose.
This guide provides prerequisites and step-by-step instructions for configuring and starting a Team Edition cluster with these
orchestrators.

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

- Linux, macOS, or Windows operating systems. We recommend Ubuntu 20.04 or newer
- Minimum 16GB RAM
- Minimum 50GB storage, > 100GB recommended
- Git
- An OCI container management tool such as Docker or Podman
- Docker Compose v2 **version 2.10 or above** or Podman Compose
    - If you install `docker-compose-plugin`, make sure to use the `docker compose` command instead of `docker-compose`.

Ensure all TCP ports from the below list are available in your network stack.
 - 80/tcp
 - 443/tcp (for HTTPS access)

> Note:
If you plan on deploying Team Edition with [Podman on Linux](#prerequisites-for-podman-on-linux), with [any container management tool
on RHEL](#prerequisites-for-rehhat-enterprise-linux-docker-or-podman), or [on Windows](#windows-specific-instructions),
please ensure you have met the prerequisites listed down below in corresponding sections or by clicking the links.

## User and permissions changes  

Starting from DBeaver Team Edition v25.0 process inside the container now runs as the ‘dbeaver’ user (‘UID=8978’), instead of ‘root’.  
If a user with ‘UID=8978’ already exists in your environment, permission conflicts may occur.  
Additionally, the default Docker volumes directory’s ownership has changed.  
Previously, the volumes were owned by the ‘root’ user, but now they are owned by the ‘dbeaver’ user (‘UID=8978’).  

## Configuring proxy server (Nginx / HAProxy)

Starting from v25.1, DBeaver Team Edition supports two types of proxy servers: Nginx and HAProxy. You can choose your preferred proxy type by setting the following variable in the .env file:

`PROXY_TYPE=nginx` # Available options: nginx, haproxy

The default value is `nginx`. Switching between proxy types is seamless: configuration files and SSL certificates are retained due to shared Docker volumes.  
However, note that the container name has changed from `nginx` to `web-proxy`.

### Proxy listen ports

When using Docker Compose with host networking mode (network_mode: host), you may configure proxy ports using these environment variables:
```
LISTEN_PORT_HTTP=80
LISTEN_PORT_HTTPS=443
```
These variables specify which ports the proxy listens to inside the container.

### Notes for Nginx users

If you use Nginx as your proxy server and customize the `COMPOSE_PROJECT_NAME` in your .env file, make sure to pass this variable explicitly to the container environment:
```
environment:
  - COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME}
```
This step is only required for Nginx, as HAProxy resolves service names via Docker DNS automatically.

## Configuring and starting Team Edition cluster

1. Clone Git repository to your local machine by running the following command in your terminal:
    ```
    git clone https://github.com/dbeaver/team-edition-deploy.git
    ```
2. Open configuration file:
    - Navigate to `team-edition-deploy/compose/cbte`
    - Copy `.env.example` to `.env`
    - Edit `.env` file to set configuration properties
3. [Configure SSL and domain](../SSL/README.md#ssl-certificate-configuration)
4. Start the cluster:
   - `docker-compose up -d` or `docker compose up -d`  

### Accessing the product

Web interface: open your browser and navigate to `https://<your-domain>` or `http://<server-ip>:<port>`.
The first time you open it, you’ll be taken straight to the Admin Panel.

[Desktop client](https://dbeaver.com/download/team-edition/): when you launch the DBeaver Team Edition desktop app, use the same URL (`https://<your-domain>` or `http://<server-ip>:<port>`) to connect to the server.

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
3. Change `CLOUDBEAVER_DB_DRIVER` to driver for a database you want to use, for example: `postgres-jdbc`/`mariaDB`/`oracle_thin`
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

#### Configure MySQL/MariaDB database

**Note:** The MySQL driver is not included in Team Edition by default. To use MySQL as an internal database, you can connect using the MariaDB driver.

Connect to your MariaDB or MySQL database and run:
```
   CREATE SCHEMA IF NOT EXISTS dc;
   CREATE SCHEMA IF NOT EXISTS qm;
   CREATE SCHEMA IF NOT EXISTS tm;
```

You might need to add additional parameters to the `CLOUDBEAVER_DB_URL`:

- `allowPublicKeyRetrieval=true` — to allow the client to automatically request the public key from the server.
- `autoReconnect=true` — to prevent the connection from closing after 8 hours of inactivity.

##### Example:

`CLOUDBEAVER_DB_URL=jdbc:mariadb://127.0.0.1:3306/cloudbeaver?autoReconnect=true&allowPublicKeyRetrieval=true`

#### Configure SQL Server database

To use SQL Server as an internal database, set the driver to `microsoft` and configure the connection URL.

Connect to your SQL Server database and run:
```
   CREATE SCHEMA dc;
   CREATE SCHEMA qm;
   CREATE SCHEMA tm;
```

##### Example:

`CLOUDBEAVER_DB_DRIVER=microsoft`  
`CLOUDBEAVER_DB_URL=jdbc:sqlserver://127.0.0.1:1433;databaseName=cloudbeaver`

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

### Standard update procedure (recommended)

1. Navigate to `team-edition-deploy/compose/cbte`
2. Stop the cluster: `docker-compose down` or `docker compose down`
3. Update your deployment files:
   - Fetch latest changes: `git fetch`
   - Switch to new release version: `git checkout <version-tag>` (e.g., `git checkout 25.2.0`)
   - Change value of `CLOUDBEAVER_VERSION_TAG` in `.env` with a preferred version (skip if tag `latest` is set)
4. Pull new docker images: `docker-compose pull` or `docker compose pull`
5. Start the cluster: `docker-compose up -d` or `docker compose up -d`

### Alternative update procedure (for simple updates)

If you are not updating across major version boundaries and don't need configuration changes:

1. Navigate to `team-edition-deploy/compose/cbte`
2. Change value of `CLOUDBEAVER_VERSION_TAG` in `.env` with a preferred version. Go to next step if tag `latest` is set.
3. Pull new docker images: `docker-compose pull` or `docker compose pull`  
4. Restart cluster: `docker-compose up -d` or `docker compose up -d`

**Note:** The standard procedure using `docker-compose down` is recommended because it ensures clean container replacement, especially when service names or configurations change between versions.

### Version update to 25.1.0 or later

Starting from version 25.1.0, the proxy container name has changed from `nginx` to `web-proxy`. When updating to version 25.1.0 or later, you **must** use the [standard update procedure](#standard-update-procedure-recommended) with `docker-compose down` to ensure the old container is properly removed.

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

and change version tag to 24.1.0 or to higher versions

```
CLOUDBEAVER_VERSION_TAG=24.1.0
```

#### Step 3. Restart cluster

1. Stop your cluster:
- run `dbeaver-te stop` if you use script manager
- or navigate to the directory `team-edition-deploy/compose/cbte` and run `docker-compose down`
2. Start your cluster:
- run `dbeaver-te start` if you use script manager
- or navigate to the directory `team-edition-deploy/compose/cbte` and run `docker-compose up -d`  

## Troubleshooting in version update

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

---

If you experience errors when updating your cluster, like that:
```  
validating /opt/dbeaver-team-server/team-edition-deploy/compose/cbte/docker-compose.yml: volumes.api_tokens.driver_opts.device must be a string or number  
```

Follow the next steps:  


1. Open the file: `team-edition-deploy/compose/cbte/docker-compose.yml`   
2. Find the volume configuration for `api_tokens` and update it by replacing `null` with the correct host path `/var/dbeaver/api_tokens`  
Before:
```
  api_tokens:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: null
```
After:
```
  api_tokens:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /var/dbeaver/api_tokens
```
3. Create `/var/dbeaver/api_tokens` folder on your server
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

### Prerequisites for Podman on Linux

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

### Prerequisites for RehHat Enterprise Linux (Docker or Podman)

To configure Team Edition on RedHat, run these commands as user `root` before [Configuring and starting Team Edition cluster](#configuring-and-starting-team-edition-cluster):

```
loginctl enable-linger 1000
echo 'net.ipv4.ip_unprivileged_port_start=80' >> /etc/sysctl.conf
sysctl -p
setsebool -P httpd_can_network_relay 1
setsebool -P httpd_can_network_connect 1
semanage permissive -a httpd_t
```

### Windows-specific instructions

For Windows-specific instructions, please refer to the [Windows.md](Windows.md) file in this directory.
