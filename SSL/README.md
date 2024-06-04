## SSL certificate configuration

The cluster supports HTTP and HTTPS. By default, it contains a pre-configured SSL certificate. You can change it to your own existing certificate associated with your domain, or configure an SSL certificate along with a new domain using the Team Edition Domain Manager.


### How to add certificate from your domain provider

1. Get certificates for your domain from the service you use. You need two files: SSL certificate and a Private Key.  
2. Navigate to the following directory:
- If you deploy Team Edition with docker-compose: `team-edition-deploy/compose/cbte/nginx/ssl`
- If you use for deployment preconfigured AMI in Amazon, Google Cloud, or Microsoft Azure:`/opt/dbeaver-team-server/team-edition-deploy/compose/cbte/nginx/ssl`
3. Replace the content of this directory with your SSL certificate and Private Key files:
   - SSl Certificate: `fullchain.pem`  
   - Private Key: `privkey.pem`  
4. Open `.env` file and change `CLOUDBEAVER_DOMAIN` parameter value to your domain.  
5. Stop your cluster with command `dbeaver-te stop`  
6. Run the installation script `./install.sh`
7. Start your cluster with command `dbeaver-te start`  

### How to generate domain with Team Edition domain service

1. Open your Team Edition instance.
2. If you are in the process of initial server configuration, navigate to **Domain manager** tab. If your Team Edition is already configured, navigate to **Settings -> Administration -> Domain Manager**.
3. The system will guide you through obtaining a domain and setting up certificates.
4. After receiving the domain and setting up the certificates, you will be automatically.
