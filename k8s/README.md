## Team Edition Helm chart for Kubernetes

- [Minimum requirements](#minimum-requirements)
- [Deployment](#deployment)
  - [How to run services](#how-to-run-services)
  - [Version update](#version-update-procedure)
- [Additional configuration](#additional-configuration)
  - [OpenShift deployment](#openshift-deployment)
  - [AWS ALB configuration ](../AWS/aws-eks/README.md#aws-alb-configuration-for-kubernetes-deployment)
  - [Digital Ocean proxy configuration](#digital-ocean-proxy-configuration)
  - [Real client IP](#real-client-ip)
  - [Clouds volumes configuration](#clouds-volumes-configuration)
    - [AWS](../AWS/aws-eks/README.md#aws-volumes-configuration-for-kubernetes-deployment)
    - [Google Cloud](../GCP/gke/README.md)
    - [Azure](../Azure/aks/README.md)
- [Backup and Restore](#backup-and-restore)


### Minimum requirements

* Kubernetes >= 1.23
* 2 CPUs
* 16Gb RAM
* Linux or macOS as deploy host
* `git` and `kubectl` installed
* [Nginx load balancer](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/) and [Kubernetes Helm plugin](https://helm.sh/docs/topics/plugins/) added to your `k8s`

### User and permissions changes

Starting from DBeaver Team Edition v25.0 process inside the container now runs as the ‘dbeaver’ user (‘UID=8978’), instead of ‘root’.  
If a user with ‘UID=8978’ already exists in your environment, permission conflicts may occur.  
Additionally, the default Docker volumes directory’s ownership has changed.  
Previously, the volumes were owned by the ‘root’ user, but now they are owned by the ‘dbeaver’ user (‘UID=8978’).  

### Deployment

#### How to run services

**Note:** If you want to store Team Edition data in cloud storage, make sure to [configure cloud volumes](#clouds-volumes-configuration) first.

1. Clone this repository from GitHub: `git clone https://github.com/dbeaver/team-edition-deploy`
2. `cd team-edition-deploy/k8s/cbte`
3. `cp ./values.yaml.example ./values.yaml`
4. Edit chart values in `values.yaml` (use any text editor).
   - You must set the `cloudbeaver_db_password` variable before deploying the cluster. The database password is empty by default and the deployment will fail without it.
5. Configure domain and SSL certificate:
  - Add an A record in your DNS hosting for a value of `cloudbeaverBaseDomain` variable with load balancer IP address.
  - Generate internal services certificates:  
     On Linux or macOS, run the script to prepare services certificates:   
       `./services-certs-generator.sh`
  - If you set the *HTTPS* endpoint scheme, then create a valid TLS certificate for the domain endpoint `cloudbeaverBaseDomain` and place it into `k8s/cbte/ingressSsl`:  
    - Certificate: `ingressSsl/fullchain.pem`  
    - Private Key: `ingressSsl/privkey.pem`
6. Deploy Team Edition with Helm: `helm install cloudbeaver-te ./ --values ./values.yaml`

#### Version update procedure

Keep your existing `values.yaml` and database PVC. Do not copy the new `values.yaml.example` over it. The example selects PostgreSQL 18 for new installations; a chart without `postgres.image` keeps PostgreSQL 13. Changing the image does not migrate an existing database.

1. Change directory to `team-edition-deploy/k8s/cbte`.
2. Update your deployment files:
   - Fetch the latest changes: `git fetch`.
   - Switch to the branch for the version you're updating to: `git checkout <version>` (for example, `git checkout 26.1.0`).
3. Change the value of `imageTag` in the `values.yaml` configuration file to the preferred version. Skip this step if the tag is set to `latest`.
4. Upgrade the cluster: `helm upgrade cloudbeaver-te ./ --values ./values.yaml`.

### Additional configuration

#### OpenShift deployment

You need additional configuration changes to deploy Team Edition in OpenShift.

1. In `values.yaml` change the `ingressController` value to `haproxy`
2. Add security context:
  Uncomment the following lines in `cloudbeaver-*.yaml` files in [templates/deployment](cbte/templates/deployment):
    ```yaml
          # securityContext:
          #     runAsUser: 1000
          #     runAsGroup: 1000
          #     fsGroup: 1000
          #     fsGroupChangePolicy: "Always"
    ```

#### Digital Ocean proxy configuration

For a managed DigitalOcean load balancer, enable PROXY protocol on both the load balancer and ingress controller. These settings do not apply to k3s ServiceLB (Klipper).

In the ingress controller Service annotations:

- `service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"`
- `service.beta.kubernetes.io/do-loadbalancer-hostname: "cloudbeaverBaseDomain"`

For community ingress-nginx, also set `use-proxy-protocol: "true"` in its controller ConfigMap and restrict `proxy-real-ip-cidr` to the trusted load balancer source ranges. Coordinate both changes to avoid interrupting traffic.

#### Real client IP

The example values disable forwarded-header processing (`forwardProxy: false`). After restricting backend access to trusted proxies and sanitizing incoming headers as described below, opt in through chart values:

```yaml
forwardProxy: true
ingressAnnotations: {}
```

`forwardProxy` sets `CLOUDBEAVER_APP_FORWARD_PROXY` on the Team Edition web application. Set it to `false` to disable forwarded-header processing. Omitting it preserves the image/configuration default; old values files keep their previous behavior. It does not change the configuration of the separate DC/RM/QM/TM services.

`ingressAnnotations` adds or overrides annotations for the selected controller without duplicate keys. It applies to both the web and backend Ingress resources. For example:

```yaml
ingressController: aws-alb
ingressAnnotations:
  alb.ingress.kubernetes.io/load-balancer-attributes: "routing.http.xff_header_processing.mode=append"
```

The chart configures the application and its Ingress resources, not an external ingress controller or its Service. Configure that upstream separately:

| Traffic path | Required upstream configuration |
| --- | --- |
| k3s ServiceLB or source-preserving L4 LB → ingress | Preserve source IP; use `externalTrafficPolicy: Local` on the ingress controller's external Service where needed. Send traffic only to nodes with ready local ingress endpoints. |
| ALB → application | Forward `X-Forwarded-For` (ALB defaults to append mode). `externalTrafficPolicy: Local` does not recover the client IP from ALB connections. |
| ALB / trusted HTTP proxy → ingress | Configure ingress to use forwarded headers only from trusted upstream ranges. For community ingress-nginx, review `use-forwarded-headers`, `enable-real-ip`, and `proxy-real-ip-cidr`. |
| NLB → ingress | For instance targets, preserve source IP and avoid Service SNAT (usually `Local`). For IP targets, check `preserve_client_ip.enabled` and network support. Alternatively, enable PROXY protocol v2 on both NLB and ingress. |

**Trust boundary:** enable `forwardProxy` only when backend access is restricted to trusted proxies (network policy/firewall/security groups). The chart does not enforce this restriction. The first trusted HTTP proxy must remove client-supplied `Forwarded` and `X-Forwarded-*` headers and construct authoritative values; subsequent proxies must trust only known upstreams. ALB append mode alone does not sanitize a forged leading `X-Forwarded-For` entry: use a sanitizing trusted edge if clients can supply these headers. Never trust arbitrary source CIDRs. If the upstream has already lost the IP without forwarding it, the chart cannot recover it.

After deployment, make a fresh request/session and compare the expected public client IP with ingress access logs and QM audit records. A node/pod address indicates source-IP loss upstream. Also verify that forged forwarded headers do not change the recorded IP and that direct backend access is blocked.

#### AWS ALB configuration

If you want to use AWS Application Load Balancer as ingress controller, [follow this instruction](../AWS/aws-eks/README.md#aws-alb-configuration-for-kubernetes-deployment).

#### Clouds volumes configuration

- [AWS](../AWS/aws-eks/README.md#aws-volumes-configuration-for-kubernetes-deployment)
- [Google Cloud](../GCP/gke/README.md)
- [Azure](../Azure/aks/README.md)

### Backup and Restore

Backup and restore procedures are outlined in [a separate document](Backup-and-Restore.md).
