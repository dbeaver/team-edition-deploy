## Upgrading to Team Edition ≥ 25.1.0

### **Reason:**  
In versions prior to `25.1.0` the Team Edition images stored TLS certificates inside the containers itself and exposed them through the `CLOUDBEAVER_DC_CERT_PATH` variable. Version `25.1.0` moves the certificates out of the image and mounts them from a shared EFS volume; the variable is therefore removed. Your certificates were originally generated locally and should still be present in `build/cert/`. Only if that folder is empty do you need to pull the files out of the previously‑deployed image (see step 2). Once the certificates are in place, commit the updated Terraform code and load them into the new EFS volume with the one‑shot migration script.

### 1. Stash your local variables.tf before switching branches

`team-edition-deploy/AWS/ecs-fargate/variables.tf` has been tracked by Git since the first deployment;  
Git will block a branch checkout unless you stash them first:
```bash
cd team-edition-deploy/AWS/ecs-fargate
git stash push -m "backup variables.tf" variables.tf
git fetch --all
git checkout 25.1.0 
git stash pop
```
### 2.  Collect your current certificates
1) Ensure that you have keys/certs into **`team-edition-deploy/AWS/ecs-fargate/build/cert/`** with the exact layout:
```
team-edition-deploy/AWS/ecs-fargate/build/cert/
├─ private/
│   ├─ dc-key.key
│   ├─ secret-cert.crt
│   └─ secret-key.key
└─ public/
    └─ dc-cert.crt
```

2) If you are not, you still can take it out from your pushed images in **AWS ECR**

**Login to AWS ECR** *(skip if you can already `docker pull` from AWS ECR)*  

Set `REGION` to the AWS region where both your existing deployment and this ECR repository live, then authenticate:
```bash
REGION=<aws_region>
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region $REGION \
| docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
```

Locate the `cloudbeaver-dc` image URI from your **AWS ECR** with two options:  
1) Automatic - ask Terraform for the repository URL (`jq` must be installed)
```bash
terraform show -json | jq -r '
  .values.root_module.resources[]
  | select(.type=="aws_ecr_repository")
  | select(.values.name|test(".*cloudbeaver-dc"))
  | .values.repository_url'
```  
2) Manual - open the **AWS ECR** console and copy the URI of the `cloudbeaver-dc` repository yourself.

Define the placeholders and substitute them below before running the command:  
`<IMAGE_URI>` – full repository URI of the `cloudbeaver-dc` image you just copied  
`<OLD_TAG>`  – tag of the version that is currently deployed (≤ 25.1.0)  

Execute the command to migrate the certificates from the container into the local `build/cert/` folder:
```bash
mkdir -p build/cert/public build/cert/private

docker run --rm --entrypoint="" \
  -v "$(pwd)/build/cert":/out \
  <IMAGE_URI>:<OLD_TAG> \
  bash -c 'cp /etc/cloudbeaver/private/* /out/private && \
           cp /etc/cloudbeaver/public/* /out/public/'
```

### 3.  Upgrade your stack to 25.1.0
1. Remove `CLOUDBEAVER_DC_CERT_PATH` from `variables.tf` – this path is no longer used.
2. Apply Terraform as usual. The EFS volume for certificates will mount for each service.
3. Wait until AWS ECS shows the new task-definition revision for each service.

### 4.  Run the one‑shot migration script
Run it in **team-edition-deploy/AWS/ecs-fargate** so it can see `build/cert/` and `variables.tf`  
```bash
./migration_certs.sh
```
The script copies your local certificates from `build/cert/` into the container’s EFS volume mounted at `/conf/certificates`. 
