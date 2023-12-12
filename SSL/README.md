### SSL certificate configuration

#### If you want to use official certificates from Domain hosting providers

1. Get certificates for your domain from a third party service. You need an SSL certificate file and public-private key pair.
2. Replace files in `/opt/dbeaver-team-server/team-edition-deploy/compose/cbte/nginx/ssl`
   - Certificate: `fullchain.pem`  
   - Private Key: `privkey.pem`
3. Change `CLOUDBEAVER_DOMAIN=localhost` to your domain in .env file.
4. Enter `dbeaver-te stop` and `dbeaver-te start` to accept new config.


#### If you want use Let's Encrypt self-signed certificate

1. You must use one of the following users: `ubuntu` (`sudo su - ubuntu`) or `ec2-user` (`sudo su - ec2-user`).
2. Make sure you have configured the variables correctly in `.env` file at Team Edition server home `/opt/dbeaver-team-server/team-edition-deploy/compose/cbte/`:
  - `CLOUDBEAVER_DOMAIN` as your domain
  - `LETSENCRYPT_CERTBOT_EMAIL` as your email to receive notifications
3. Run `dbeaver-te le`
