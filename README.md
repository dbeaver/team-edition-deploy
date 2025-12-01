## DBeaver Team Edition

#### Version 25.3.0

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

### Desktop Application

DBeaver Team Edition works in conjunction with a desktop client application. After deploying the server, you can connect to it using:
- **Web interface** – accessible directly through your browser
- **Desktop client** – provides enhanced features and better performance

Download the desktop client for your platform: [**DBeaver Team Edition Desktop**](https://dbeaver.com/downloads-team/25.3.0/)

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
- [25.2.0](https://github.com/dbeaver/team-edition-deploy/tree/25.2.0)
- [25.1.0](https://github.com/dbeaver/team-edition-deploy/tree/25.1.0)
- [25.0.0](https://github.com/dbeaver/team-edition-deploy/tree/25.0.0)
- [24.3.0](https://github.com/dbeaver/team-edition-deploy/tree/24.3.0)
- [24.2.0](https://github.com/dbeaver/team-edition-deploy/tree/24.2.0)
- [24.1.0](https://github.com/dbeaver/team-edition-deploy/tree/24.1.0)
- [24.0.0](https://github.com/dbeaver/team-edition-deploy/tree/24.0.0)
- [23.3.0](https://github.com/dbeaver/team-edition-deploy/tree/23.3.0)
- [23.2.0](https://github.com/dbeaver/team-edition-deploy/tree/23.2.0)
- [23.1.0](https://github.com/dbeaver/team-edition-deploy/tree/23.1.0)
- [23.0.0](https://github.com/dbeaver/team-edition-deploy/tree/23.0.0)
