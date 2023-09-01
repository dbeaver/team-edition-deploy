## Team Edition Helm chart for AWS AMI

#### Minimum requirements:

* t2.large
* 2 CPUs
* 8Gb RAM


### How to use manager

- You can use `teambeaver` for managment all service on your server
- Enter `teambeaver` or `teambeaver help` to see help menu


### Configuration SSL certificate

- Replace files in `/opt/dbeaver-team-server/team-edition-deploy/compose/cbte/nginx/ssl`
  Certificate: `/fullchain.pem`  
  Private Key: `/privkey.pem`
- Change `CLOUDBEAVER_DOMAIN=localhost` to your domain in .env file
- Enter `teambeaver stop` and `teambeaver start` for accept new config


### Version update procedure.

- Enter `teambeaver update list`
- Choose version what you want to update
- `teambeaver update %version%`