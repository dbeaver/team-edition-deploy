## Team Edition Helm chart for AWS AMI

#### Minimum requirements:

* t2.xlarge instance
* 4 CPUs
* 16Gb RAM

### How to deploy AMI in AWS

- Go to AWS EC2 > Launch instance
- Choose `DBeaver Team Edition` in AWS Marketplace AMIs
- Use recommended instance type t2.xlarge (or larger) for the best experience with this product
- For your secure not recommended make the service public 
- Launch instance

### How to use manager

- You can use `teambeaver` for managment of all services on your server
- Enter `teambeaver` or `teambeaver help` to see help menu


### Configuration SSL certificate

- Replace files in `/opt/dbeaver-team-server/team-edition-deploy/compose/cbte/nginx/ssl`
   - Certificate: `/fullchain.pem`  
   - Private Key: `/privkey.pem`
- Change `CLOUDBEAVER_DOMAIN=localhost` to your domain in .env file
- Enter `teambeaver stop` and `teambeaver start` to accept new config


### Version update procedure.

- Enter `teambeaver update list`
- Choose the version which you want to update
- `teambeaver update %version%`