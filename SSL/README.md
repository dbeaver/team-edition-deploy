## SSL certificate configuration
 
By default, the cluster has fake HTTPS certificates and you may see an error about an insecure connection, they will be generated automatically witch running nginx image.

### If you want to use official certificates from Domain hosting providers

1. Get certificates for your domain from a third party service. You need an SSL certificate file and public-private key pair.  
2. Replace files in `/opt/dbeaver-team-server/team-edition-deploy/compose/cbte/nginx/ssl`  
   - Certificate: `fullchain.pem`    
   - Private Key: `privkey.pem`  
3. Change `CLOUDBEAVER_DOMAIN=localhost` to your domain in .env file.  
4. Stop your cluster with command `dbeaver-te stop`  
5. Run `./install.sh`script  
6. Start your cluster with command `dbeaver-te start`  

### If you want to use our domain service

If you have license key you can get domain with https certificates from our domain manager service.

1. During Easy Config
  - Easy Config: During the easy configuration process, follow the prompts.
  - Obtain Domain: The system will guide you through obtaining a domain and setting up certificates.
  - After receiving the domain and setting up the certificates, you will be automatically redirected to the new domain.
2. After Easy Config  
  - Navigate to Administration.  
  - Select Domain Manager.  
  - Set Up Domain: Follow the instructions to set up your domain and configure certificates as needed.  
  - After receiving the domain and setting up the certificates, you will be automatically redirected to the new domain.  
