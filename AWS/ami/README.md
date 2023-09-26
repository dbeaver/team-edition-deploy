## Team Edition deployment for AWS AMI

#### Minimum requirements:

* 4 CPUs
* 16GB RAM
* 100GB Storage (SSD recommended)


### How to deploy AMI in AWS

- Go to [AWS EC2](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1) -> AMI Catalog -> Community AMIs
- Find `dbeaver-te-server-ubuntu-23-2-0`

![example](image.png)

- Launch instance

#### Note:
- Use recommended `Minimum requirements` resources for the best experience with this product
- For security reasons, it is not recommended to make the service public in security group configuration


### How to use manager

`dbeaver-te` is a utility to manage a Team Edition server. Using this manager, you can start or stop the server, as well as update its version.

- Connect to your server through the terminal
- Enter dbeaver-te or dbeaver-te help to see help menu


### SSL certificate configuration

- Replace files in `/opt/dbeaver-team-server/team-edition-deploy/compose/cbte/nginx/ssl`
   - Certificate: `fullchain.pem`  
   - Private Key: `privkey.pem`
- Change `CLOUDBEAVER_DOMAIN=localhost` to your domain in .env file
- Enter `dbeaver-te stop` and `dbeaver-te start` to accept new config


### Version update procedure

The update occurs with the help of the manager

- Enter `dbeaver-te update list`
- Choose the version you want to update
- `dbeaver-te update %version%`