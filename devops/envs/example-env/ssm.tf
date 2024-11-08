resource "aws_ssm_parameter" "db_host" {
  name   = "/${var.environment}/db_host"
  type   = "SecureString"
  value  = module.db_default.db_instance_address
  key_id = "alias/aws/ssm"
}

resource "aws_ssm_parameter" "db_name" {
  name   = "/${var.environment}/db_name"
  type   = "SecureString"
  value  = module.db_default.db_instance_name
  key_id = "alias/aws/ssm"

}

resource "aws_ssm_parameter" "db_port" {
  name   = "/${var.environment}/db_port"
  type   = "SecureString"
  value  = module.db_default.db_instance_port
  key_id = "alias/aws/ssm"
}

resource "aws_ssm_parameter" "rds_credentials_secret_arn" {
  name   = "/${var.environment}/rds_credentials_secret_arn"
  type   = "SecureString"
  value  = module.db_default.db_managed_secret_credentials_arn
  key_id = "alias/aws/ssm"
}

resource "aws_ssm_parameter" "rds_credentials_kms_key" {
  name   = "/${var.environment}/rds_credentials_kms_key"
  type   = "SecureString"
  value  = module.db_default.db_managed_secret_credentials_encryption_key
  key_id = "alias/aws/ssm"
}

resource "aws_ssm_parameter" "db_instance_resource_id" {
  name   = "/${var.environment}/db_instance_resource_id"
  type   = "SecureString"
  value  = module.db_default.db_instance_resource_id
  key_id = "alias/aws/ssm"
}
