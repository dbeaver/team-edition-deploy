resource "aws_ecr_repository" "dbeaver_te" {
  count = length(var.ecr_repositories)
  name  = "${var.deployment_id}-team-${element(var.ecr_repositories, count.index)}"
  image_tag_mutability = "MUTABLE"
  force_delete = "true"

  image_scanning_configuration {
    scan_on_push = true
  }
}

locals {

  dkr_build_cmd = <<-EOT

          cd build

          export AWS_REGION="${var.aws_region}"
          export AWS_ACC_ID="${var.aws_account_id}"
          export DEPLOYMENT_ID="${var.deployment_id}"

          export TESERVICES="${join(" ", [for s in var.ecr_repositories : format("%q", s)])}"
          export TEVERSION="${var.dbeaver_te_version}"

          ./build-dbeaverte.sh

          cd ..
    EOT

}

# local-exec for build and push of docker image
resource "null_resource" "build_push_dkr_img" {
  triggers = {
    image_ver_changed = var.dbeaver_te_version
  }
  provisioner "local-exec" {
    command = local.dkr_build_cmd
  }

  depends_on = [aws_ecr_repository.dbeaver_te]
}

output "trigged_by" {
  value = null_resource.build_push_dkr_img.triggers
}