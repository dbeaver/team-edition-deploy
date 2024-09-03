variable "aws_account_id" {
  description = "Your AWS account ID"
  type = string
  default = ""
}

variable "aws_region" {
  description = "Region where you plan to deploy"
  type    = string
  default = ""
}

variable "dbeaver_te_version" {
  description = "The version of the cluster you want to deploy"
  type = string
  default = "24.1.0"
}

variable "alb_certificate_Identifier" {
  description = "Your certificate ID from AWS Certificate Manager"
  type = string
  default = ""
}

variable "environment" {
  description = "The environment name (e.g., Dev, Test, Prod)"
  type        = string
  default     = "Prod"
}

variable "rds_db" {
  description = "A boolean flag to select Amazon RDS as internal database"
  type        = bool
  default     = false
}

variable "rds_db_type" {
  description = "Type of RDS DB instance"
  type        = string
  default     = "postgres"
}

variable "rds_db_version" {
  description = "Version of type RDS DB instance"
  type        = string
  default     = "16.1"
}


variable "cloudbeaver-db-env" {
  description = "Parameters for your internal database"
  # type = map(string)
  default = [
    { "name": "POSTGRES_PASSWORD",
     "value": "postgres"},
    { "name": "POSTGRES_USER",
     "value": "postgres"},
    { "name": "POSTGRES_DB",
     "value": "cloudbeaver"}
  ]
}

variable "ecr_repositories" {
  type = list
  default = ["dc", "rm", "qm", "te", "tm", "postgres"]
}

variable "dbeaver_te_default_ns" {
  type = string
  default = "dbeaver-te.local"
}

variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
 type        = list(string)
 description = "Public Subnet CIDR values"
 default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
 type        = list(string)
 description = "Private Subnet CIDR values"
 default     = ["10.0.4.0/24", "10.0.5.0/24"]
}

variable "cloudbeaver-kafka-env" {
  # type = map(string)
  default = [
    { "name" : "KAFKA_CFG_NODE_ID",
    "value" : "0" },
    { "name" : "KAFKA_BROKER_ID",
    "value" : "0" },
    { "name" : "KAFKA_ENABLE_KRAFT",
    "value" : "yes" },
    { "name" : "ALLOW_PLAINTEXT_LISTENER",
    "value" : "yes" },
    { "name" : "KAFKA_CFG_PROCESS_ROLES",
    "value" : "controller,broker" },
    { "name" : "KAFKA_CFG_CONTROLLER_QUORUM_VOTERS",
    "value" : "0@127.0.0.1:9093" },
    { "name" : "KAFKA_CFG_LISTENERS",
    "value" : "PLAINTEXT://:9092,CONTROLLER://:9093" },
    { "name" : "KAFKA_CFG_ADVERTISED_LISTENERS",
    "value" : "PLAINTEXT://:9092" },
    { "name" : "KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP",
    "value" : "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT" },
    { "name" : "KAFKA_CFG_CONTROLLER_LISTENER_NAMES",
    "value" : "CONTROLLER" },
    { "name" : "KAFKA_CFG_INTER_BROKER_LISTENER_NAME",
    "value" : "PLAINTEXT" }
    ]
}


variable "cloudbeaver-dc-env" {
  # type = map(string)
  default = [{
      "name": "CLOUDBEAVER_DC_SERVER_URL",
      "value": "http://cloudbeaver-dc:8970/dc"
  },
  {
      "name": "CLOUDBEAVER_QM_SERVER_URL",
      "value": "http://cloudbeaver-qm:8972/qm"
  },
  {
      "name": "CLOUDBEAVER_RM_SERVER_URL",
      "value": "http://cloudbeaver-rm:8971/rm"
  },
  {
      "name": "CLOUDBEAVER_TM_SERVER_URL",
      "value": "http://cloudbeaver-tm:8973/tm"
  },
  {
      "name": "CLOUDBEAVER_DC_BACKEND_DB_URL",
      "value": "jdbc:postgresql://postgres:5432/cloudbeaver"
  },
  {
      "name": "CLOUDBEAVER_QM_BACKEND_DB_URL",
      "value": "jdbc:postgresql://postgres:5432/cloudbeaver"
  },
  {
      "name": "CLOUDBEAVER_TM_BACKEND_DB_URL",
      "value": "jdbc:postgresql://postgres:5432/cloudbeaver"
  },
  {
      "name": "CLOUDBEAVER_QM_BACKEND_DB_DRIVER",
      "value": "postgres-jdbc"
  },
  {
      "name": "CLOUDBEAVER_DC_BACKEND_DB_DRIVER",
      "value": "postgres-jdbc"
  },
  {
      "name": "CLOUDBEAVER_TM_BACKEND_DB_DRIVER",
      "value": "postgres-jdbc"
  },
  {
      "name": "CLOUDBEAVER_DC_BACKEND_DB_USER",
      "value": "dc"
  },
  {
      "name": "CLOUDBEAVER_QM_BACKEND_DB_USER",
      "value": "qm"
  },
  {
      "name": "CLOUDBEAVER_TM_BACKEND_DB_USER",
      "value": "tm"
  },
  {
      "name": "CLOUDBEAVER_DC_BACKEND_DB_PASSWORD",
      "value": "DCpassword"
  },
  {
      "name": "CLOUDBEAVER_TM_BACKEND_DB_PASSWORD",
      "value": "TMpassword"
  },
  {
      "name": "CLOUDBEAVER_QM_BACKEND_DB_PASSWORD",
      "value": "QMpassword"
  },
  {
      "name": "CLOUDBEAVER_DC_CERT_PATH",
      "value": "/etc/cloudbeaver/private"
  },
  {
      "name": "CLOUDBEAVER_PUBLIC_URL",
      "value": "https://cloudbeaver.io"
  }]
}

variable "cloudbeaver-shared-env" {
  # type = map(string)
  default = [{
      "name": "CLOUDBEAVER_DC_SERVER_URL",
      "value": "http://cloudbeaver-dc:8970/dc"
  },
  {
      "name": "CLOUDBEAVER_DC_CERT_PATH",
      "value": "/etc/cloudbeaver/public"
  }]
}
