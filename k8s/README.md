## Team Edition Helm chart for Kubernetes

- [Minimum requirements](#minimum-requirements)
- [Deployment](#deployment)
  - [How to run services](#how-to-run-services)
  - [Version update](#version-update-procedure)
- [Additional configuration](#additional-configuration)
  - [OpenShift deployment](#openshift-deployment)
  - [AWS ALB configuration ](#aws-alb-configuration)
  - [Digital Ocean proxy configuration](#digital-ocean-proxy-configuration)
  - [Clouds volumes configuration](#clouds-volumes-configuration)
    - [AWS](#aws)
    - [Google Cloud](#google-cloud)


### Minimum requirements

* Kubernetes >= 1.23
* 2 CPUs
* 16Gb RAM
* Linux or macOS as deploy host
* `git` and `kubectl` installed
* [Nginx load balancer](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/) and [Kubernetes Helm plugin](https://helm.sh/docs/topics/plugins/) added to your `k8s`

### Deployment

#### How to run services

**Note:** If you want to store Team Edition data in cloud storage, make sure to [configure cloud volumes](#clouds-volumes-configuration) first.

1. Clone this repository from GitHub: `git clone https://github.com/dbeaver/team-edition-deploy`
2. `cd team-edition-deploy/k8s/cbte`
3. `cp ./values.example.yaml ./values.yaml`
4. Edit chart values in `values.yaml` (use any text editor).
5. Configure domain and SSL certificate:
  - Add an A record in your DNS hosting for a value of `dbeaverTEBaseDomain` variable with load balancer IP address.
  - Generate internal services certificates:  
     On Linux or macOS, run the script to prepare services certificates:   
       `./services-certs-generator.sh`
  - If you set the *HTTPS* endpoint scheme, then create a valid TLS certificate for the domain endpoint `dbeaverTEBaseDomain` and place it into `k8s/cbte/ingressSsl`:  
    - Certificate: `ingressSsl/fullchain.pem`  
    - Private Key: `ingressSsl/privkey.pem`
6. Deploy Team Edition with Helm: `helm install cloudbeaver-te ./ --values ./values.yaml`

#### Version update procedure

1. Change directory to `team-edition-deploy/k8s/cbte`.
2. Change value of `imageTag` in configuration file `values.yaml` with a preferred version. Go to next step if tag `latest` is set.
3. Upgrade cluster: `helm upgrade cloudbeaver-te ./ --values ./values.yaml`

### Additional configuration

#### OpenShift deployment

You need additional configuration changes to deploy Team Edition in OpenShift.

1. In `values.yaml` change the `ingressController` value to `haproxy`
2. Add security context:
  Uncomment the following lines in `dbeaver-te-*.yaml` files in [templates/deployment](cbte/templates/deployment):
    ```yaml
          # securityContext:
          #     runAsUser: 1000
          #     runAsGroup: 1000
          #     fsGroup: 1000
          #     fsGroupChangePolicy: "Always"
    ```

#### AWS ALB configuration  

If you want to use [AWS Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) as ingress controller, follow this instruction.

Install `AWS CLI`: If `AWS CLI` is not installed yet, install it by following the instructions on the [official AWS CLI website](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).  

Install `eksctl`: `eksctl` is a command-line utility for creating and managing EKS clusters. Install eksctl by following the instructions on the [official eksctl website](https://eksctl.io/installation/).  


Policy required for eksctl to work:

- [CloudFormation Full Access](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AWSCloudFormationFullAccess.html)
- [EKS Full Access](https://docs.aws.amazon.com/eks/latest/userguide/security_iam_id-based-policy-examples.html#security_iam_id-based-policy-examples-console)
- [EC2 and EC2 Auto Scaling Full Access](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEC2FullAccess.html)
- [IAM Full Access](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/IAMFullAccess.html)
- [Systems Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/security_iam_id-based-policy-examples.html)

1. OIDC Provider Association:  

```
eksctl utils associate-iam-oidc-provider --region=<your-region> --cluster=<your-cluster-name> --approve
```

2. Create IAM role and link policy:  

Create policy IAM:  
```
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json
```

Create IAM role and link policy:  
```
eksctl create iamserviceaccount \
  --cluster <your-cluster-name> \
  --region <your-region> \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::<your-account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```

3. Install AWS Load Balancer Controller using Helm:  

```
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<your-cluster-name> \
  --set serviceAccount.create=false \
  --set region=<your-region> \
  --set vpcId=<your-vpc-id> \
  --set serviceAccount.name=aws-load-balancer-controller
```

#### Digital Ocean proxy configuration

Edit ingress controller with:

- `kubectl edit service -n ingress-nginx ingress-nginx-controller`

and add two lines in the `metadata.annotations`

- `service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"`
- `service.beta.kubernetes.io/do-loadbalancer-hostname: "dbeaverTEBaseDomain"`

#### Clouds volumes configuration

##### AWS

To store Team Edition data in the cloud, you need to configure cloud volumes. For example, you can store connection configurations and user information in AWS EFS.


###### Prerequisites

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed and configured
- [eksctl](https://eksctl.io/installation/) installed
- [Helm](https://helm.sh/docs/intro/install/) installed
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) installed
- Access to an existing **EKS cluster**

Policy required:

- [AmazonElasticFileSystemFullAccess](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonElasticFileSystemFullAccess.html)

###### Step 1: Associate IAM OIDC Provider

Associate the IAM OIDC provider with your EKS cluster to enable IAM roles for service accounts.

```
eksctl utils associate-iam-oidc-provider \
  --region=<your-region> \
  --cluster=<your-cluster-name> \
  --approve
```

###### Step 2: Install AWS EFS and EBS CSI Drivers

Install the AWS EFS and EBS CSI drivers using Helm.

```
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver/
helm repo update

helm install aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver --namespace kube-system
helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --namespace kube-system
```

###### Step 3: Configure EFS via Terraform

1. Navigate to directory `team-edition-deploy/AWS/aws-eks`
2. Open the `main.tf` file in a text editor.
3. Update the following variables with your AWS region and EKS cluster name:
```
variable "region" {
  description = "Region for AWS EFS"
  default     = "<your-region>"
}
variable "cluster_name" {
  description = "EKS cluster name"
  default     = "<your-cluster-name>"
}
```
4. Run `terraform init`.
5. Next, run `terraform apply`, which will output `efs_file_system_id`.
6. Open the file `team-edition-deploy/k8s/cbte/values.yaml` and update the `fileSystemId` parameter with the value of `efs_file_system_id` obtained in the previous step.
7. Fill in the other parameters as shown in the example:

```
cloudProvider: aws
storage:
  type: efs
  storageClassName: "efs-sc"
  efs:
    fileSystemId: "<your-efs-id>"

```

Once this is set up, you can deploy Team Edition by following [this guide](#how-to-run-services).

##### Google Cloud

###### Prerequisites

- [gcloud](https://cloud.google.com/sdk/docs/install) installed and configured
- [Helm](https://helm.sh/docs/intro/install/) installed
- Access to an existing **GKE cluster**

###### Step 1: Enable the Cloud Filestore API and the Google Kubernetes Engine API

```
gcloud services enable file.googleapis.com container.googleapis.com
```

###### Step 2: Configure values.yaml file

Open the file `team-edition-deploy/k8s/cbte/values.yaml` and fill in the following parameters as shown in the example:

```
cloudProvider: gcp
storage:
  type: filestore
  storageClassName: "filestore-sc"
```

Once this is set up, you can deploy Team Edition by following [this guide](#how-to-run-services).
