## DBeaver TE Helm chart for Kubernetes

#### Minimum requrements:

* Kubernetse >= 1.23
* 2 cpus
* 8Gb Ram
* Linux or MacOS as deploy host
* git and kubectl clents installed on deploy host
* [Nginx LoadBallancer](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/) and [Kubernetes Helm plugin](https://helm.sh/docs/topics/plugins/) added to you k8s

#### How to run services

* Configure kubectl tool for using your kebernetes instance 
* Clone this repo from GitHub:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`git clone https://github.com/dbeaver/team-edition-deploy`

* Edit chart values in `k8s/cbte/values.yaml`

* Add an A record in your DNS hosting for a value of `cloudbeaverBaseDomain` variable with LoadBallancer IP address.

* Generate internal services certificates:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;on linux or macos run script for prepare services certificates: 

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`cd k8s/cbte`

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`./services-certs-generator.sh`

* If you set *https* endpoint scheme than create valid TLS certificate for a domain endpoint `cloudbeaverBaseDomain` and place it into `k8s/cbte/ingressSsl`:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Certificate: `k8s/cbte/ingressSsl/fullchain.pem`

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Private Key: `k8s/cbte/ingressSsl/privkey.pem`

* Deploy DBeaver TE with Helm:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; in `k8s` dirrectory

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; `helm install cloudbeaver ./cbte`


#### DO proxy hack

Edit ingress controller with:

&nbsp;&nbsp;&nbsp;&nbsp; `kubectl edit service -n ingress-nginx ingress-nginx-controller`

and add two lines in `metadata.annotations`

&nbsp;&nbsp;&nbsp;&nbsp; *service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"*

&nbsp;&nbsp;&nbsp;&nbsp; *service.beta.kubernetes.io/do-loadbalancer-hostname: `cloudbeaverBaseDomain`*
