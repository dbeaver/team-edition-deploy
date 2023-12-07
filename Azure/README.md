- [Deployment](#deployment)
- [Setup and control options](#setup-and-control-options)
  - [Team Edition server manager](#team-edition-server-manager)
  - [Version update procedure](version-update-procedure)

## Deployment

1. Log in to [Microsoft Azure Portal](https://portal.azure.com/) and navigate to **Azure -> Community images**.

![Alt text](image.png)

2. Enter `dbeaver-te-server` in the search field, select location, then the version, and press **Create VM**.


![Alt text](image-1.png)

3. Fill in the required fields:

![Alt text](image-2.png)

- Choose VM size with recommended resources 4 vCPUs and 16 GiB RAM

![Alt text](machine-type.png)

- In the field **Inbound port rules** select 22, 80, and 443 ports.

![Alt text](image-3.png)

- You must configure the SSH user as `ubuntu` proper server management, and enter your SSH key or specify an existing one.


![Alt text](image-4.png)

- That's all done. The other fields are not required.

## Setup and control options

### Team Edition server manager

`dbeaver-te` is a utility to manage a Team Edition server. Using this manager, you can start or stop the server, as well as update its version.

How to user manager:

1. Connect to your server through the terminal.

2. Enter `dbeaver-te` or `dbeaver-te help` to see the help menu.


### SSL certificate configuration

#### If you want to use official certificates from CDN services

1. Get certificates for your domain from a third party service (for example [Cloudflare](https://www.cloudflare.com/learning/ssl/what-is-an-ssl-certificate/) )
2. Replace files in `/opt/dbeaver-team-server/team-edition-deploy/compose/cbte/nginx/ssl` (you mast be user `ubuntu` or `ec2-user`)
   - Certificate: `fullchain.pem`  
   - Private Key: `privkey.pem`
3. Change `CLOUDBEAVER_DOMAIN=localhost` to your domain in .env file
4. Enter `dbeaver-te stop` and `dbeaver-te start` to accept new config


#### If you want use let's encrypt self-signed certificate

1. You mast be user `ubuntu` or `ec2-user`
2. Make sure you have configured the variables correctly in .env file at DBeaver TE server home `/opt/dbeaver-team-server/team-edition-deploy/compose/cbte/`
  - `CLOUDBEAVER_DOMAIN` as your domain 
  - `LETSENCRYPT_CERTBOT_EMAIL` as your email to receive notifications
3. Run `dbeaver-te lecert`


### Version update procedure

The update occurs with the help of the [manager](#team-edition-server-manager).

1. Connect to your server through the terminal.
2. Enter `dbeaver-te update list`
3. Choose the version you want to update.
4. Run this command: `dbeaver-te update %version%`