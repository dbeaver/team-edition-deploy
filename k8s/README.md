## Team Edition Helm chart for Kubernetes

#### Minimum requirements:

* Kubernetes >= 1.23
* 2 CPUs
* 16Gb RAM
* Linux or macOS as deploy host
* `git` and `kubectl` installed
* [Nginx load balancer](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/) and [Kubernetes Helm plugin](https://helm.sh/docs/topics/plugins/) added to your `k8s`

### How to run services

**Note:** If you want to store Team Edition data in cloud storage, make sure to [configure cloud volumes](#clouds-volumes-configuration) first.

- Clone this repo from GitHub: `git clone https://github.com/dbeaver/team-edition-deploy`
- `cd team-edition-deploy/k8s/cbte`
- `cp ./values.example.yaml ./values.yaml`
- Edit chart values in `values.yaml` (use any text editor)
- Configure domain and SSL certificate (optional)
  - Add an A record in your DNS hosting for a value of `cloudbeaverBaseDomain` variable with load balancer IP address.
  - Generate internal services certificates:  
     On Linux or macOS, run the script to prepare services certificates:   
       `./services-certs-generator.sh`
  - If you set the *HTTPS* endpoint scheme, then create a valid TLS certificate for the domain endpoint `cloudbeaverBaseDomain` and place it into `k8s/cbte/ingressSsl`:  
    Certificate: `ingressSsl/fullchain.pem`  
    Private Key: `ingressSsl/privkey.pem`
- Deploy Team Edition with Helm: `helm install cloudbeaver`

### Version update procedure

- Change directory to `team-edition-deploy/k8s/cbte`.
- Change value of `imageTag` in configuration file `values.yaml` with a preferred version. Go to next step if tag `latest` set.
- Upgrade cluster: `helm upgrade cloudbeaver`

### OpenShift deployment

You need additional configuration changes

- In `values.yaml` change the `ingressController` value to `haproxy`
- Add security context  
  Uncomment the following lines in `cloudbeaver-*.yaml` files in [templates/deployment](cbte/templates/deployment):
    ```yaml
          # securityContext:
          #     runAsUser: 1000
          #     runAsGroup: 1000
          #     fsGroup: 1000
          #     fsGroupChangePolicy: "Always"
    ```

### Digital Ocean proxy configuration

Edit ingress controller with:

- `kubectl edit service -n ingress-nginx ingress-nginx-controller`

and add two lines in the `metadata.annotations`

- `service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"`
- `service.beta.kubernetes.io/do-loadbalancer-hostname: "cloudbeaverBaseDomain"`

### Clouds volumes configuration

To store Team Edition data in the cloud, you need to configure cloud volumes. For example, you can store connection configurations and user information in AWS EFS.

Once this is set up, you can deploy Team Edition by following [this guide](#how-to-run-services).

#### AWS

##### Prerequisites

- **AWS CLI** installed and configured
- **eksctl** installed
- **Helm** installed
- **Terraform** installed
- Access to an existing **EKS cluster**


##### Step 1: Associate IAM OIDC Provider

Associate the IAM OIDC provider with your EKS cluster to enable IAM roles for service accounts.

```
eksctl utils associate-iam-oidc-provider \
  --region=<your-region> \
  --cluster=<your-cluster-name> \
  --approve
```

##### Step 2: Install AWS EFS and EBS CSI Drivers

Install the AWS EFS and EBS CSI drivers using Helm.

```
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver/
helm repo update

helm install aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver --namespace kube-system
helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --namespace kube-system
```

##### Step 3: Configure EFS via Terraform

1. Navigate to Directory `team-edition-deploy/AWS/aws-eks`
2. Open the `main.tf` file in a text editor
3. Update the following variables with your AWS region and EKS cluster name
```
variable "region" {
  description = "Region for AWS EFS"
  default     = ""<your-region>"
}
variable "cluster_name" {
  description = "EKS cluster name"
  default     = "<your-cluster-name>"
}
```
4. Run `terraform init` and `terraform apply`
5. Take `efs_file_system_id` after complite deployment and put it in `storage.efs.fileSystemId` in `team-edition-deploy/k8s/cbte/values.yaml` file
6. Set in `team-edition-deploy/k8s/cbte/values.yaml` in `cloudProvider` to `aws`


#### GCP 

##### Prerequisites

- [gcloud](https://cloud.google.com/sdk/docs/install) installed and configured
- **Helm** installed
- Access to an existing **GKE cluster**

##### Step 1: Enable the Cloud Filestore API and the Google Kubernetes Engine API 

```
gcloud services enable file.googleapis.com container.googleapis.com
```

##### Step 2: Configure values.yaml file 

Set in `team-edition-deploy/k8s/cbte/values.yaml`

```
cloudProvider: gcp 
storage:
  type: filestore
  storageClassName: "filestore-sc"
```

Once this is set up, you can deploy Team Edition by following [this guide](#how-to-run-services).