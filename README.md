## DBeaver Team Edition

#### Version 23.2

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
        - [AWS ECS](AWS/aws-ecs-fargate/) - create and deploy ECS cluster

### Server initial configuration

After you started the server:

- Go to deployed server URL (e.g. `http://localhost/` in the simplest case)
- Login as `cbadmin`/`cbadmin20`
- Configure your license
- That's it

Now you can use web interface or [desktop clients](https://dbeaver.com/download/team-edition/) to work with your databases

#### How to change db password for already deployed clusters

To change an internal postgres password use [this instruction](CHANGEPWD.md#how-to-change-db-password-for-already-deployed-clusters).

### Early Access:

- [Early access](https://github.com/dbeaver/team-edition-deploy/tree/ea)

### Older versions:

- [23.1.0](https://github.com/dbeaver/team-edition-deploy/tree/23.1.0)
- [23.0.0](https://github.com/dbeaver/team-edition-deploy/tree/23.0.0)