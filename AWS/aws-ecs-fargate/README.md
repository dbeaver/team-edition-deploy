### DBeaver TE deployment for AWS ECS and Fargate with Terraform.


1. Navigate to the `/build` directory.

2. Configure the following variables in the respective files:
   - In `ecr.tf`, set `dbeaver-aws-region` to your desired AWS region.
   - In `build-dbeaverte.sh`, set `AWS_REGION` and `AWS_ACC_ID` according to your AWS configuration.

3. Update the passwords in both the `cloudbeaver-db-init.sql` file and the `variables.tf` file. Modify the following password variables:
   - `CLOUDBEAVER_DC_BACKEND_DB_PASSWORD`
   - `CLOUDBEAVER_QM_BACKEND_DB_PASSWORD`
   - `CLOUDBEAVER_TM_BACKEND_DB_PASSWORD`

4. Run `terraform init` and then `terraform apply` to create the necessary repositories for the services.

5. Execute `./build-dbeaverte.sh` to quickly build and push Docker images to the Amazon Elastic Container Registry (ECR). You can customize the deployment version by updating the `TEVERSION` environment variable. The default version is `23.2.0`.

6. Make a backup of the `build/cert` directory and store it in a secure location for safekeeping.

7. Return to the `aws-ecs-fargate` directory and configure the deployment in `variables.tf` as follows:
   - Ensure that the `alb_certificate_arn` variable contains the ARN of the SSL certificate corresponding to your domain specified in `CLOUDBEAVER_PUBLIC_URL`.
   - Change all `*_PASSWORD` fields to secure values according to your security requirements.

8. Run `terraform init` and then `terraform apply` to create the ECS cluster and complete the deployment.
