## Team Edition Helm chart for Kubernetes

#### Minimum requirements:

* Kubernetes >= 1.23
* 2 CPUs
* 8GB RAM
* Linux or macOS as deploy host
* `git` and `kubectl` installed on the deploy host
* [Nginx load balancer](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/) and [Kubernetes Helm plugin](https://helm.sh/docs/topics/plugins/) added to your `k8s`

### How to run services

1. Configure `kubectl` tool for using your Kubernetes instance 
2. Clone this repo from GitHub:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`git clone https://github.com/dbeaver/team-edition-deploy`
3. Create `k8s/cbte/values.yaml` from `k8s/cbte/example.values.yaml`
4. Edit chart values in `k8s/cbte/values.yaml`
   1. If on OpenShift, change the `ingressController` value to `haproxy`
5. Add security context (OpenShift only)  
  Uncomment the following lines in `cloudbeaver-*.yaml` files in [templates/deployment](cbte/templates/deployment):  
    ```yaml
          # securityContext:
          #     runAsUser: 1000
          #     runAsGroup: 1000
          #     fsGroup: 1000
          #     fsGroupChangePolicy: "Always"
    ```
6. Add an A record in your DNS hosting for a value of `cloudbeaverBaseDomain` variable with load balancer IP address.
7. Generate internal services certificates:  
   On Linux or macOS, run the script to prepare services certificates:   
     `cd k8s/cbte`  
     `./services-certs-generator.sh`
8. If you set the *HTTPS* endpoint scheme, then create a valid TLS certificate for the domain endpoint `cloudbeaverBaseDomain` and place it into `k8s/cbte/ingressSsl`:  
  Certificate: `k8s/cbte/ingressSsl/fullchain.pem`  
  Private Key: `k8s/cbte/ingressSsl/privkey.pem`
9. Deploy Team Edition with Helm:  
  in the `k8s` directory  
  `helm install cloudbeaver ./cbte`

### Version update procedure.

1. Change directory to `team-edition-deploy/k8s`.

2. Change value of `imageTag` in configuration file `k8s/cbte/values.yaml` with a preferred version. Go to next step if tag `latest` set.

3. Upgrade cluster: `helm upgrade cloudbeaver ./cbte` 


#### DO proxy hack

Edit ingress controller with:

&nbsp;&nbsp;&nbsp;&nbsp; `kubectl edit service -n ingress-nginx ingress-nginx-controller`

and add two lines in the `metadata.annotations`

&nbsp;&nbsp;&nbsp;&nbsp; *service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"*

&nbsp;&nbsp;&nbsp;&nbsp; *service.beta.kubernetes.io/do-loadbalancer-hostname: `cloudbeaverBaseDomain`*
