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
- Configure domain and SSL certificate (optional)
  - Add an A record in your DNS hosting for a value of `cloudbeaverBaseDomain` variable with load balancer IP address.
  - Generate internal services certificates:  
     On Linux or macOS, run the script to prepare services certificates:   
       `./services-certs-generator.sh`
  - If you set the *HTTPS* endpoint scheme, then create a valid TLS certificate for the domain endpoint `cloudbeaverBaseDomain` and place it into `k8s/cbte/ingressSsl`:  
    Certificate: `ingressSsl/fullchain.pem`  
    Private Key: `ingressSsl/privkey.pem`
- If you are using GKE for deployment, you first need to [create a Cloud NAT gateway to deploy in GKE.](#create-cloud-nat-gateway-to-gke-deployment)
- First you must [deploy NGINX Ingress Controller](#deploy-nginx-ingress-controller)
- Deploy Team Edition with Helm: `helm install cloudbeaver`

#### Deploy NGINX Ingress Controller

1. Add the `nginx-stable` Helm repository:

        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
        helm repo update

2.  Deploy an NGINX controller Deployment and Service:

        helm install nginx-ingress ingress-nginx/ingress-nginx

3.  Verify that the `nginx-ingress-controller` Deployment and Service are deployed:

        kubectl get deployment nginx-ingress-ingress-nginx-controller
        kubectl get service nginx-ingress-ingress-nginx-controller

    The output should look like this:

        # Deployment
        NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
        nginx-ingress-ingress-nginx-controller   1/1     1            1           13m

        # Service
        NAME                                     TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)                      AGE
        nginx-ingress-ingress-nginx-controller   LoadBalancer   10.7.255.93   <pending>       80:30381/TCP,443:32105/TCP   13m
        
    Wait a few moments while load balancer gets deployed, and then confirm that the `nginx-ingress-nginx-ingress` Service has been deployed
    and that you have an external IP address associated with the service:

        kubectl get service nginx-ingress-ingress-nginx-controller

    You may need to run this command a few times until an `EXTERNAL-IP` value is present.

### Version update procedure.

- Change directory to `team-edition-deploy/k8s/cbte`.
- Change value of `imageTag` in configuration file `values.yaml` with a preferred version. Go to next step if tag `latest` set.
- Upgrade cluster: `helm upgrade cloudbeaver` 


### Cloud deployment configurations

#### Create Cloud NAT gateway to GKE deployment

If you plan to use GKE for deployment, it is assumed that you already have a GKE cluster.

In order to provide external connectivity to GKE clusters, you need to create a [Cloud NAT gateway](https://cloud.google.com/nat/docs/overview).

You must have [gcloud CLI](https://cloud.google.com/sdk/gcloud) installed. The `us-east1` region is taken for example, replace it with your region.

1.  Create and reserve an external IP address for the NAT gateway:

        gcloud compute addresses create us-east1-nat-ip \
            --region=us-east1

2.  Create a Cloud NAT gateway for the private GKE cluster:

        gcloud compute routers create rtr-us-east1 \
            --network=default \
            --region us-east1

        gcloud compute routers nats create nat-gw-us-east1 \
            --router=rtr-us-east1 \
            --region us-east1 \
            --nat-external-ip-pool=us-east1-nat-ip \
            --nat-all-subnet-ip-ranges \
            --enable-logging


In the end you must connect your domain from `cloudbeaverBaseDomain` to `EXTERNAL-IP`, and then you can connect to the Team Edition cluster.

#### OpenShift deployment

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

#### Digital Ocean proxy configuration

Edit ingress controller with:

- `kubectl edit service -n ingress-nginx ingress-nginx-controller`

and add two lines in the `metadata.annotations`

- `service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"`
- `service.beta.kubernetes.io/do-loadbalancer-hostname: "cloudbeaverBaseDomain"`
