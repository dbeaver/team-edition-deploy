## Team Edition deployment for AWS AMI

#### Minimum requirements:

* 4 CPUs
* 16GB RAM
* 100GB Storage (SSD recommended)


### How to deploy AMI in AWS

- Go to AWS Marketplace
- Choose [DBeaver Team Edition](https://aws.amazon.com/marketplace/pp/prodview-kijugxnqada5i?sr=0-2&ref_=beagle&applicationId=AWSMPContessa)
- Use recommended instance resources for the best experience with this product
- For security reasons, it is not recommended to make the service public
- Launch instance

### How to use manager

`dbeaver-te` is a utility to manage a Team Edition server. Using this manager, you can start or stop the server, as well as update its version.

- Connect to your server through the terminal
- Enter `dbeaver-te` or `dbeaver-te help` to see help menu


### Configuration SSL certificate

- Replace files in `/opt/dbeaver-team-server/team-edition-deploy/compose/cbte/nginx/ssl`
   - Certificate: `/fullchain.pem`  
   - Private Key: `/privkey.pem`
- Change `CLOUDBEAVER_DOMAIN=localhost` to your domain in .env file
- Enter `dbeaver-te stop` and `dbeaver-te start` to accept new config


### Version update procedure

The update occurs with the help of the manager

- Enter `dbeaver-te update list`
- Choose the version you want to update
- `dbeaver-te update %version%`