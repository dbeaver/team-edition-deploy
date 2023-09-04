## Team Edition Helm chart for AWS AMI

#### Minimum requirements:

* 4 CPUs
* 16Gb RAM
* 100G Disk (SSD recommended)

### How to deploy AMI in AWS

- Go to AWS Marketplace
- Choose [DBeaver Team Edition](https://aws.amazon.com/marketplace/pp/prodview-kijugxnqada5i?sr=0-2&ref_=beagle&applicationId=AWSMPContessa)
- Use recommended instance resources for the best experience with this product
- For your secure not recommended make the service public 
- Launch instance

### How to use manager

- You can use `dbeaver-te` for managment of all services on your server
- Enter `dbeaver-te` or `dbeaver-te help` to see help menu


### Configuration SSL certificate

- Replace files in `/opt/dbeaver-team-server/team-edition-deploy/compose/cbte/nginx/ssl`
   - Certificate: `/fullchain.pem`  
   - Private Key: `/privkey.pem`
- Change `CLOUDBEAVER_DOMAIN=localhost` to your domain in .env file
- Enter `dbeaver-te stop` and `dbeaver-te start` to accept new config


### Version update procedure.

- Enter `dbeaver-te update list`
- Choose the version which you want to update
- `dbeaver-te update %version%`