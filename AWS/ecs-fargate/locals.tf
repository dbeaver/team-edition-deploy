locals {
  rds_db_url = var.rds_db ? "jdbc:postgresql://${module.rds[0].db_instance_address}:5432/cloudbeaver" : ""

  cloudbeaver_dc_env_modified = [
    for item in var.cloudbeaver-dc-env : {
      name = item.name
      value = (
        item.name == "CLOUDBEAVER_DC_BACKEND_DB_URL" ? (var.rds_db ? local.rds_db_url : format("jdbc:postgresql://%s-postgres:5432/cloudbeaver", var.deployment_id)) :
        item.name == "CLOUDBEAVER_QM_BACKEND_DB_URL" ? (var.rds_db ? local.rds_db_url : format("jdbc:postgresql://%s-postgres:5432/cloudbeaver", var.deployment_id)) :
        item.name == "CLOUDBEAVER_TM_BACKEND_DB_URL" ? (var.rds_db ? local.rds_db_url : format("jdbc:postgresql://%s-postgres:5432/cloudbeaver", var.deployment_id)) :
        item.name == "CLOUDBEAVER_DC_SERVER_URL" ? format("http://%s-cloudbeaver-dc:8970/dc", var.deployment_id) :
        item.name == "CLOUDBEAVER_QM_SERVER_URL" ? format("http://%s-cloudbeaver-qm:8972/qm", var.deployment_id) :
        item.name == "CLOUDBEAVER_RM_SERVER_URL" ? format("http://%s-cloudbeaver-rm:8971/rm", var.deployment_id) :
        item.name == "CLOUDBEAVER_TM_SERVER_URL" ? format("http://%s-cloudbeaver-tm:8973/tm", var.deployment_id) :
        item.name == "CLOUDBEAVER_KAFKA_BROKERS" ? format("%s-kafka:9092", var.deployment_id) :
        item.value
      )
    }
  ]

  cloudbeaver_shared_env_modified = [
    for item in var.cloudbeaver-shared-env : {
      name = item.name
      value = (
        item.name == "CLOUDBEAVER_DC_SERVER_URL" ? format("http://%s-cloudbeaver-dc:8970/dc", var.deployment_id) :
        item.value
      )
    }
  ]

  postgres_password = { for item in var.cloudbeaver-db-env : item.name => item.value }["POSTGRES_PASSWORD"]
  postgres_user     = { for item in var.cloudbeaver-db-env : item.name => item.value }["POSTGRES_USER"]

  updated_cloudbeaver_dc_env = [for item in local.cloudbeaver_dc_env_modified : {
    name = item.name
    value = (
      item.name == "CLOUDBEAVER_DC_BACKEND_DB_PASSWORD" ? local.postgres_password :
      item.name == "CLOUDBEAVER_QM_BACKEND_DB_PASSWORD" ? local.postgres_password :
      item.name == "CLOUDBEAVER_TM_BACKEND_DB_PASSWORD" ? local.postgres_password :
      item.name == "CLOUDBEAVER_DC_BACKEND_DB_USER" ? local.postgres_user :
      item.name == "CLOUDBEAVER_QM_BACKEND_DB_USER" ? local.postgres_user :
      item.name == "CLOUDBEAVER_TM_BACKEND_DB_USER" ? local.postgres_user :
      item.value
    )
  }]
}
