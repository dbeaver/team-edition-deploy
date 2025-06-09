## Upgrading to Team Edition ≥ 25.1.0 for AWS ECS and Fargate with Terraform

In versions prior to `25.1.0` the Team Edition images stored TLS certificates inside the containers  and exposed them using the `CLOUDBEAVER_DC_CERT_PATH` variable.

Starting with version `25.1.0`, certificates are no longer bundled in the container image. Instead, they are mounted from a shared EFS volume, and the `CLOUDBEAVER_DC_CERT_PATH` variable has been removed.

Previously, your certificates were generated locally and should still be available in the `build/cert/` directory. If that folder is empty, you’ll need to extract the certificates from your previously deployed container.

Once the certificates are restored, update your Terraform configuration and upload the certificates to the new EFS volume using the migration script.


### Step 1. Stash your local variables.tf before switching branches

The file `team-edition-deploy/AWS/ecs-fargate/variables.tf` is tracked by Git from the first deployment. To avoid conflicts, Git will prevent branch checkout unless you stash local changes first.

```bash
cd team-edition-deploy/AWS/ecs-fargate
git stash push -m "backup variables.tf" variables.tf
git fetch --all
git checkout 25.1.0
git stash pop
```
### Step 2.  Collect your current certificates

Make sure your certificates are available in the following directory structure:

```
team-edition-deploy/AWS/ecs-fargate/build/cert/
├─ private/
│   ├─ dc-key.key
│   ├─ secret-cert.crt
│   └─ secret-key.key
└─ public/
    └─ dc-cert.crt
```

If the certificate and key files are in place, proceed to Step 4.

If the `build/cert/` directory is missing or incomplete, you can extract the certificates from your existing deployed image stored in **AWS ECR**.

### Step 3. Extract certificates from AWS ECR (if needed)

#### 3.1. Log in to AWS ECR with Docker

If you're unable to run `docker pull` from AWS ECR, set the `REGION` to match the AWS region where both your existing deployment and the ECR repository are located, then authenticate:

```bash
REGION=<aws_region>
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region $REGION \
| docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
```

#### 3.2. Find the cloudbeaver-dc image URI

You can get this URI automatically via Terraform or manually via AWS Console.

**Option 1: Automatically via Terraform (requires `jq`)**

```bash
terraform show -json | jq -r '
  .values.root_module.resources[]
  | select(.type=="aws_ecr_repository")
  | select(.values.name|test(".*cloudbeaver-dc"))
  | .values.repository_url'
```  
**Option 2: Manually via AWS ECR console**

Open the AWS ECR console and manually copy the URI of the `cloudbeaver-dc` repository.


#### 3.3. Copy certificates

Run the following command to extract the certificates from the container and place them into the local `build/cert/` directory:

```bash
mkdir -p build/cert/public build/cert/private

docker run --rm --entrypoint="" \
  -v "$(pwd)/build/cert":/out \
  <IMAGE_URI>:<OLD_TAG> \
  bash -c 'cp /etc/cloudbeaver/private/* /out/private && \
           cp /etc/cloudbeaver/public/* /out/public/'
```

Where:

- <IMAGE_URI> — the full URI of the cloudbeaver-dc image retrieved in Step 3.2
- <OLD_TAG> — the tag of the currently deployed version (must be 25.1.0 or earlier)

### 4.  Upgrade your stack to 25.1.0

1. Open `team-edition-deploy/AWS/ecs-fargate/variables.tf` and remove the `CLOUDBEAVER_DC_CERT_PATH` variable — this value is no longer needed.
2. Apply Terraform as usual. The certificate EFS volume will be automatically mounted to each service.
3. Wait for AWS ECS to show that all services are running the new task definition revision.

### 5.  Run the migration script

After applying Terraform, run this script to move the certificates into the new shared EFS volume.

1. Go to team-edition-deploy/AWS/ecs-fargate directory
2. Run `./migration_certs.sh`

This script copies your local certificates from `build/cert/` into the container’s EFS volume at `/conf/certificates`.
