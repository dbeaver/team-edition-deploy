variable "ecr_repositories" {
  type = list
  default = ["dc", "rm", "qm", "te", "db"]
}

variable "dbeaver-aws-region" {
  type    = string
  default = ""
}

provider "aws" {
  region = var.dbeaver-aws-region
}



resource "aws_ecr_repository" "dbeaver_te" {
  count = length(var.ecr_repositories)
  name                 = "cloudbeaver-${element(var.ecr_repositories, count.index)}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}