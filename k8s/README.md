## Team Edition Helm chart for Kubernetes

#### Minimum requirements:

* Kubernetes >= 1.23
* 2 CPUs
* 16Gb RAM
* Linux or macOS as deploy host
* `git` and `kubectl` installed

[//]: # (* [Nginx load balancer]&#40;https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/&#41; and [Kubernetes Helm plugin]&#40;https://helm.sh/docs/topics/plugins/&#41; added to your `k8s`)

### How to run services
- Clone this repo from GitHub: `git clone https://github.com/dbeaver/team-edition-deploy`
- `cd team-edition-deploy/k8s/cbte`
- `cp ./values.example.yaml ./values.yaml`
- Edit chart values in `values.yaml` (use any text editor)
- Configure domain and SSL certificate 
  - Add an A record in your DNS hosting for a value of `cloudbeaverBaseDomain` variable with load balancer IP address.
  - Generate internal services certificates:  
     On Linux or macOS, run the script to prepare services certificates:   
       `./services-certs-generator.sh`
  - If you set the *HTTPS* endpoint scheme, then create a valid TLS certificate for the domain endpoint `cloudbeaverBaseDomain` and place it into `k8s/cbte/ingressSsl`:  
    Certificate: `ingressSsl/fullchain.pem`  
    Private Key: `ingressSsl/privkey.pem`
- Deploy Team Edition with Helm: `helm install cloudbeaver-te ./ --values ./values.yaml`

### Version update procedure.

- Change directory to `team-edition-deploy/k8s/cbte`.
- Change value of `imageTag` in configuration file `values.yaml` with a preferred version. Go to next step if tag `latest` set.
- Upgrade cluster: `helm upgrade cloudbeaver-te ./ --values ./values.yaml` 

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

### AWS ALB configuration  

Install `AWS CLI`: If `AWS CLI` is not installed yet, install it by following the instructions on the [official AWS CLI website](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).  

Install `eksctl`: `eksctl` is a command-line utility for creating and managing EKS clusters. Install eksctl by following the instructions on the [official eksctl website](https://eksctl.io/installation/).  


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

3. Installing AWS Load Balancer Controller using Helm:  

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

### Digital Ocean proxy configuration

Edit ingress controller with:

- `kubectl edit service -n ingress-nginx ingress-nginx-controller`

and add two lines in the `metadata.annotations`

- `service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"`
- `service.beta.kubernetes.io/do-loadbalancer-hostname: "cloudbeaverBaseDomain"`
