locals {
  service_name = local.prefix
  cw_log_group = "/aws/ecs/${local.prefix}"
}

resource "aws_cloudwatch_log_group" "backend_fargate_task" {
  name = "${local.cw_log_group}-backend"
  tags = {
    Name = "${local.service_name}-backend",
  }
}

resource "aws_cloudwatch_log_group" "migration_fargate_task" {
  name = "${local.cw_log_group}-backend-migrations"
  tags = {
    Name = "${local.service_name}-backend-migrations",
  }
}

resource "aws_cloudwatch_log_group" "django-delegate" {
  name = "/backend/delegate-activity"
  tags = {
    Name = "${local.service_name}-django-delegate",
  }
}

resource "aws_cloudwatch_log_group" "django-admin" {
  name = "/backend/admin-activity"
  tags = {
    Name = "${local.service_name}-django-admin",
  }
}
resource "aws_cloudwatch_log_group" "django-server" {
  name = "/backend/server"
  tags = {
    Name = "${local.service_name}-django-server",
  }
}
