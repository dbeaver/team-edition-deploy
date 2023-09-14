## Team Edition deployment for AWS AMI

#### Minimum requirements:

* 4 CPUs
* 16GB RAM
* 100GB Storage (SSD recommended)


### How to deploy AMI in AWS

- Go to AWS EC2 -> AMI Catalog -> Community AMIs
- Find `dbeaver-te-server-ubuntu-23-2-0` (`ami-0897bbdc0845df8a9`)

![example](image.png)

- Use recommended instance resources for the best experience with this product
- For security reasons, it is not recommended to make the service public
- Launch instance

### How to use manager

- You can use `dbeaver-te` for managment of all services on your server
- Enter `dbeaver-te` or `dbeaver-te help` to see help menu


### Configuration SSL certificate

- Replace files in `/opt/dbeaver-team-server/team-edition-deploy/compose/cbte/nginx/ssl`
   - Certificate: `fullchain.pem`  
   - Private Key: `privkey.pem`
- Change `CLOUDBEAVER_DOMAIN=localhost` to your domain in .env file
- Enter `dbeaver-te stop` and `dbeaver-te start` to accept new config


### Version update procedure.

- Enter `dbeaver-te update list`
- Choose the version you want to update
- `dbeaver-te update %version%`