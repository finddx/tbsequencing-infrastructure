resource "aws_db_subnet_group" "default" {
  name       = "${local.prefix}-sng"
  subnet_ids = var.low_cost_implementation ? [module.vpc.public_subnets[0], module.vpc.public_subnets[1]] : [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
}

module "db_default" {
  source = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//rds?ref=rds-v1.1"

  identifier                     = replace("${local.prefix}-default", "-", "")
  instance_use_identifier_prefix = false

  create_db_option_group              = true
  create_db_parameter_group           = true
  iam_database_authentication_enabled = true
  performance_insights_enabled        = true
  parameters = [
    {
      name  = "password_encryption"
      value = "md5"
    }
  ]

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = "14.12"
  family               = "postgres14" # DB parameter group
  major_engine_version = "14"         # DB option group
  instance_class       = var.low_cost_implementation ? "db.t4g.micro" : "db.t4g.small"

  allocated_storage = var.low_cost_implementation ? 50 : 100

  ca_cert_identifier = "rds-ca-rsa2048-g1"

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  # NOTE: having db name and username depend on environment specific variables is a bad idea
  # NOTE: you can't change the master username nor the db name (it's AWS RDS operated)
  # NOTE: this means you can't export DB snapshots between environments
  # NOTE: because they will have different user and database names !
  # NOTE: thus db_name and username = CONSTANT VALUES
  db_name  = "tbkbdb"
  username = "tbkbmasteruser"
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [module.sg.security_group_id["postgresql"]]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = var.low_cost_implementation ? 1 : 7

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  create_cloudwatch_log_group = true

  depends_on = [
    aws_db_subnet_group.default
  ]
}
