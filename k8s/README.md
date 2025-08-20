## Team Edition Helm chart for Kubernetes

- [Minimum requirements](#minimum-requirements)
- [Deployment](#deployment)
  - [How to run services](#how-to-run-services)
  - [Version update](#version-update-procedure)
- [Additional configuration](#additional-configuration)
  - [OpenShift deployment](#openshift-deployment)
  - [AWS ALB configuration ](../AWS/aws-eks/README.md#aws-alb-configuration-for-kubernetes-deployment)
  - [Digital Ocean proxy configuration](#digital-ocean-proxy-configuration)
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

1. Change directory to `team-edition-deploy/k8s/cbte`.
2. Change value of `imageTag` in configuration file `values.yaml` with a preferred version. Go to next step if tag `latest` is set.
3. Upgrade cluster: `helm upgrade cloudbeaver-te ./ --values ./values.yaml`

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

Edit ingress controller with:

- `kubectl edit service -n ingress-nginx ingress-nginx-controller`

and add two lines in the `metadata.annotations`

- `service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"`
- `service.beta.kubernetes.io/do-loadbalancer-hostname: "cloudbeaverBaseDomain"`

#### AWS ALB configuration

If you want to use AWS Application Load Balancer as ingress controller, [follow this instruction](../AWS/aws-eks/README.md#aws-alb-configuration-for-kubernetes-deployment).

#### Clouds volumes configuration

- [AWS](../AWS/aws-eks/README.md#aws-volumes-configuration-for-kubernetes-deployment)
- [Google Cloud](../GCP/gke/README.md)
- [Azure](../Azure/aks/README.md)

### Backup and Restore

To back up your DBeaver Team Edition deployment, you need to preserve both the database and persistent volume data.
The following steps outline how to perform a backup and restore procedure.

#### Backup Procedure

1. **Database Backup**:
    - **For in-cluster PostgreSQL**:
    ```bash
    NAMESPACE="default" # Change this to your namespace if different
    BACKUP_DB_TARGETS=$(kubectl get pods -n $NAMESPACE --no-headers | awk '{print $1}' | grep 'postgre')
    BACKUP_DIR="backups" # Change this to your desired backup directory
    kubectl exec -n $NAMESPACE $BACKUP_DB_TARGETS -- pg_dump -U postgres --format=plain -C cloudbeaver > $BACKUP_DIR/dump.sql
    ```

    - **For external or other database types**: Use the appropriate backup command for your database type and ensure proper connectivity
      to the database.

2. **Persistent Volume Backup**:

    Back up workspace data from each service's persistent volume.

    ```bash
    BACKUP_CB_TARGETS=$(kubectl get pods -n $NAMESPACE --no-headers | awk '{print $1}' | grep -vE 'kafka|postgre')
    for svc in $BACKUP_CB_TARGETS
    do
        BACKUP_DEST_DIR=$(echo "$svc" | cut -d'-' -f2)
        mkdir -p $BACKUP_DIR/$BACKUP_DEST_DIR
        kubectl cp -n "$NAMESPACE" "$svc:workspace" "$BACKUP_DIR/$BACKUP_DEST_DIR" && break
    done
    ```

3. **Archive packing**:

    ```bash
    tar czf $BACKUP_DIR.tar.gz $BACKUP_DIR/
    ```

#### Restore Procedure

1. **Unpack the backup**:

    Unpack the backup archive to a directory of your choice:

    ```bash
    ARCHIVE="" # Path to the backup archive
    tar xzf "$ARCHIVE"
    ```

2. **Restore Persistent Volume Data**:

    Restore workspace data to each service's persistent volume.

    ```bash
    NAMESPACE="default" # Change this to your namespace if different
    BACKUP_CB_TARGETS=$(kubectl -n "$NAMESPACE" get pods --no-headers | awk '{print $1}' | grep -vE 'kafka|postgre')
    for svc in $BACKUP_CB_TARGETS; do
        DIR=$(echo "$svc" | cut -d '-' -f2)
        if ! kubectl cp "$BACKUP_DIR/$DIR/." "$NAMESPACE/$svc:workspace"; then
            echo "ERROR: kubectl cp failed for pod $svc"
            continue
        fi
    done
    ```

3. **Restore Database**:

    - **For in-cluster PostgreSQL**:
    ```bash
    BACKUP_DB_TARGET=$(kubectl -n "$NAMESPACE" get pods --no-headers | awk '{print $1}' | grep postgre | head -n1)
    kubectl exec -n "$NAMESPACE" "$BACKUP_DB_TARGET" -- bash -c 'rm -rf /var/lib/postgresql/data/*'
    kubectl delete pod -n "$NAMESPACE" "$BACKUP_DB_TARGET"
    kubectl wait --for=condition=Ready -n "$NAMESPACE" pod -l app=db --timeout=180s
    NEW_DB_POD=$(kubectl -n "$NAMESPACE" get pods --no-headers | awk '{print $1}' | grep postgre | head -n1)
    sleep 10
    DB_USER=$(kubectl get pod "$NEW_DB_POD" -n "$NAMESPACE" -o jsonpath='{.spec.containers[0].env[?(@.name=="POSTGRES_USER")].value}')
    DB=$(kubectl get pod "$NEW_DB_POD" -n "$NAMESPACE" -o jsonpath='{.spec.containers[0].env[?(@.name=="POSTGRES_DB")].value}')
    kubectl exec -n "$NAMESPACE" -i "$NEW_DB_POD" -- psql -U $DB_USER $DB < "$BACKUP_DIR/dump.sql"
    ```

    - **For external or other database types**: Use the appropriate restore command for your database type while ensuring proper 
    connectivity to the database.

4. **Restart Services**:

    Restart the services to ensure they pick up the restored data.

    ```bash
    DEPLOYMENTS=$(printf '%s\n' $BACKUP_CB_TARGETS $NEW_DB_POD | awk -F'-' 'BEGIN{OFS="-"}{NF-=2;print}' | sort -u)
    kubectl -n "$NAMESPACE" rollout restart deployment $DEPLOYMENTS
    ```
