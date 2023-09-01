## DBeaver Team Edition

#### Version 23.2

DBeaver Team Edition is a client-server application.  
It requires server deployment. You can deploy it on a single host (e.g. your local computer)
or in a cloud.  

### Deployment 

- [Docker compose](compose) - the simplest way to deploy and run the server on the local machine
- [Kubernetes](k8s) - if you prefer to run everything with docker orchestration 
- [AWS AMI](ami) - if you wamt use AWS for deploy

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