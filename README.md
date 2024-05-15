## DBeaver Team Edition

#### Version 24.0

DBeaver Team Edition is a client-server application.  
It requires server deployment. You can deploy it on a single host (e.g. your local computer)
or in a cloud.  

### Deployment
 * On premise
    - [Docker compose](compose) - the simplest way to deploy and run the server on the local machine
    - [Kubernetes](k8s) - if you prefer to run everything with docker orchestration
 * Cloud
    * AWS
        - [AWS AMI](AWS/ami/) - if you want to use AWS for deployment
        - [AWS ECS](AWS/ecs-fargate/) - create and deploy ECS cluster
    * Google Cloud
        - [GCP Image](GCP/) - if you want to use GCP for deployment
    * Azure
        - [Azure Image](Azure/) - if you want to use Azure for deployment

### Server initial configuration

After you started the server:

- Go to deployed server URL (e.g. `http://localhost/` in the simplest case)
- Configure your login/password
- Configure your license
- That's it

Now you can use web interface or [desktop clients](https://dbeaver.com/download/team-edition/) to work with your databases

### Server version update  
Version update is handled differently for different deployment methods. To update the Team Edition version, follow these instructions:  

- [Docker compose](compose/README.md#version-update-procedure)  
- [Kubernetes](k8s/README.md#version-update-procedure)  
- [AWS AMI](Manager/README.md#version-update-procedure)  
- [AWS ECS](AWS/ecs-fargate/README.md#version-update)  
- [GCP Image](Manager/README.md#version-update-procedure)  
- [Azure Image](Manager/README.md#version-update-procedure)


#### How to change database password for already deployed clusters

To change an internal PostgreSQL password use [this instruction](CHANGEPWD.md#how-to-change-db-password-for-already-deployed-clusters).

### Early Access:

- [Early access](https://github.com/dbeaver/team-edition-deploy/tree/devel)

### Older versions:

- [23.3.0](https://github.com/dbeaver/team-edition-deploy/tree/23.3.0)
- [23.2.0](https://github.com/dbeaver/team-edition-deploy/tree/23.2.0)
- [23.1.0](https://github.com/dbeaver/team-edition-deploy/tree/23.1.0)
- [23.0.0](https://github.com/dbeaver/team-edition-deploy/tree/23.0.0)
