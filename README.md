## DBeaver Team Edition

#### Version 24.3

DBeaver Team Edition is a client-server application.  
It requires server deployment. You can deploy it on a single host (e.g. your local computer)
or in a cloud.  

### Deployment
**On-premise**  
- [**Docker Compose**](compose) – the simplest way to deploy and run the server locally  
- [**Kubernetes**](k8s) – for Docker orchestration

**Cloud**  
- **AWS**
  - [**AMI**](AWS/ami/) – AWS-based deployment  
  - [**ECS**](AWS/ecs-fargate/) – create and deploy an ECS cluster  
  - [**EKS**](AWS/aws-eks/README.md) – deploy with EKS
- **Google Cloud**
  - [**Image**](GCP/gcp-image) – GCP-based deployment  
  - [**GKE**](GCP/gke/README.md) – deploy with GKE
- **Azure**
  - [**Image**](Azure/azure-image) – Azure-based deployment  
  - [**AKS**](Azure/aks/README.md) – deploy with AKS

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
- [AWS AMI](manager/README.md#version-update-procedure)  
- [AWS ECS](AWS/ecs-fargate/README.md#version-update)  
- [GCP Image](manager/README.md#version-update-procedure)  
- [Azure Image](manager/README.md#version-update-procedure)


#### How to change database password for already deployed clusters

To change an internal PostgreSQL password use [this instruction](CHANGEPWD.md#how-to-change-db-password-for-already-deployed-clusters).

### Early Access:

- [Early access](https://github.com/dbeaver/team-edition-deploy/tree/devel)

### Older versions:
- [24.2.0](https://github.com/dbeaver/team-edition-deploy/tree/24.2.0)
- [24.1.0](https://github.com/dbeaver/team-edition-deploy/tree/24.1.0)
- [24.0.0](https://github.com/dbeaver/team-edition-deploy/tree/24.0.0)
- [23.3.0](https://github.com/dbeaver/team-edition-deploy/tree/23.3.0)
- [23.2.0](https://github.com/dbeaver/team-edition-deploy/tree/23.2.0)
- [23.1.0](https://github.com/dbeaver/team-edition-deploy/tree/23.1.0)
- [23.0.0](https://github.com/dbeaver/team-edition-deploy/tree/23.0.0)
