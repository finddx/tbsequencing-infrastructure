module "ecs" {
  source       = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//ecs_cluster?ref=ecs-v1.0"
  ecs_clusters = local.ecs_clusters
  environment  = var.environment
  module_name  = var.module_name
  project_name = var.project_name
}

module "ecs_tasks" {
  source           = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//ecs_tasks?ref=ecs_tasks-v1.1"
  environment      = var.environment
  task_definitions = local.task_definitions
  module_name      = var.module_name
  project_name     = var.project_name
  aws_region       = local.aws_region
  services         = local.ecs_services
}

locals {
  ecs_clusters = {
    cluster = {
      capacity_providers = ["FARGATE_SPOT", "FARGATE"]
      capacity_provider  = "FARGATE"
    }
  }
  task_definitions = {
    "${local.prefix}-backend-migrations" = {
      container_repo               = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.aws_region}.amazonaws.com/${var.project_name}-backend"
      container_tag                = "latest"
      container_name               = "${local.prefix}-backend-migrations"
      task_role_arn                = module.roles.role_arn["fargate-task"]
      execution_role_arn           = module.roles.role_arn["fargate-execution"]
      cpu                          = 1024
      memory                       = 2048
      environment_variables        = local.migrations_environments
      secret_environment_variables = local.migrations_secret_environments
      entryPoint                   = ["bash", "-c"]
      command                      = ["python --version; python manage.py migrate; python manage.py postmigrate --full --amount 50000;"]
      health_check                 = null
      log-group                    = resource.aws_cloudwatch_log_group.migration_fargate_task.name

    }

    "${local.prefix}-backend" = {
      container_repo               = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.aws_region}.amazonaws.com/${var.project_name}-backend"
      container_tag                = "latest"
      container_name               = "${local.prefix}-backend"
      task_role_arn                = module.roles.role_arn["fargate-task"]
      execution_role_arn           = module.roles.role_arn["fargate-execution"]
      cpu                          = var.low_cost_implementation ? 512 : 4096
      memory                       = var.low_cost_implementation ? 1024 : 16384
      environment_variables        = local.backend_environments
      secret_environment_variables = local.backend_secret_environments
      health_check                 = null
      port_mappings = [
        {
          hostPort : 8000,
          protocol : "tcp",
          containerPort : 8000
        }
      ]
      log-group = resource.aws_cloudwatch_log_group.backend_fargate_task.name
      tags = merge({
        Name = "${local.prefix}-backend"
      })
    }
  }

  #variables
  backend_environments = [
    {
      "name" : "ALLOWED_HOSTS",
      "value" : "${var.cf_domain},${module.alb.load_balancer_dns_name["lb"]}"
    },
    {
      "name" : "AWS_S3_REGION_NAME",
      "value" : local.aws_region
    },
    {
      "name" : "AWS_SEQUENCING_DATA_BUCKET_NAME",
      "value" : "${local.prefix}-backend-sequence-data"
    },
    {
      "name" : "AWS_SES_REGION_ENDPOINT",
      "value" : "email.${local.aws_region}.amazonaws.com"
    },
    {
      "name" : "AWS_SES_REGION_NAME",
      "value" : local.aws_region
    },
    {
      "name" : "AWS_STORAGE_BUCKET_NAME",
      "value" : "${local.prefix}-backend-media"
    },
    {
      "name" : "CORS_ALLOWED_ORIGINS",
      "value" : "https://${var.cf_domain},https://${module.alb.load_balancer_dns_name["lb"]}"
    },
    {
      "name" : "REACT_APP_SERVER_ENDPOINT",
      "value" : "https://${var.cf_domain}/api/v1"
    },
    {
      "name" : "DB_USER",
      "value" : local.db_iam_user_name
    },
    {
      "name" : "DB_HOST_PORT",
      "value" : module.db_default.db_instance_endpoint
    },
    {
      "name" : "DB_NAME",
      "value" : module.db_default.db_instance_name
    },
    {
      "name" : "DEFAULT_FROM_EMAIL",
      "value" : var.no_reply_email
    },
    {
      "name" : "DEPLOYMENT",
      "value" : "aws"
    },
    {
      "name" : "ENVIRONMENT",
      "value" : "production"
    },
    {
      "name" : "FRONTEND_DOMAIN",
      "value" : var.cf_domain
    },
    {
      "name" : "REGION",
      "value" : local.aws_region
    },
    {
      "name" : "STATIC_URL",
      "value" : "static_files/"
    },
    {
      "name" : "ECS_LOGLEVEL"
      "value" : "debug"
    },
    {
      "name" : "ENTREZ_SECRET_ARN",
      "value" : resource.aws_secretsmanager_secret.ncbi_entrez.arn
    },
    {
      "name" : "SITE_HEADER",
      "value" : "TBKB TEST DOMAIN"
    },
    {
      "name" : "DATA_UPLOAD_MAX_NUMBER_FIELDS",
      "value" : "10000"
    },
    {
      "name" : "CLOUDWATCH_LOGGROUP_ADMIN",
      "value" : resource.aws_cloudwatch_log_group.django-admin.name
    },
    {
      "name" : "CLOUDWATCH_LOGGROUP_DELEGATE",
      "value" : resource.aws_cloudwatch_log_group.django-delegate.name
    },
    {
      "name" : "CLOUDWATCH_LOGGROUP_SERVER",
      "value" : resource.aws_cloudwatch_log_group.django-server.name
    }
  ]

  backend_secret_environments = [
    {
      "name" : "SECRET_KEY",
      "valueFROM" : "${resource.aws_secretsmanager_secret.django.arn}:::${resource.aws_secretsmanager_secret_version.django.version_id}"
    },
    {
      "name" : "ADFS_TENANT_ID",
      "valueFROM" : "${resource.aws_secretsmanager_secret.adfs.arn}:ADFS_TENANT_ID::"
    },
    {
      "name" : "ADFS_CLIENT_ID",
      "valueFROM" : "${resource.aws_secretsmanager_secret.adfs.arn}:ADFS_CLIENT_ID::"
    },
    {
      "name" : "ADFS_CLIENT_SECRET",
      "valueFROM" : "${resource.aws_secretsmanager_secret.adfs.arn}:ADFS_CLIENT_SECRET::"
    }
  ]

  migrations_environments = [
    {
      "name" : "ALLOWED_HOSTS",
      "value" : "${var.cf_domain},${module.alb.load_balancer_dns_name["lb"]}"
    },
    {
      "name" : "AWS_S3_REGION_NAME",
      "value" : local.aws_region
    },
    {
      "name" : "AWS_SEQUENCING_DATA_BUCKET_NAME",
      "value" : "${local.prefix}-backend-sequence-data"
    },
    {
      "name" : "AWS_SES_REGION_ENDPOINT",
      "value" : "email.${local.aws_region}.amazonaws.com"
    },
    {
      "name" : "AWS_SES_REGION_NAME",
      "value" : local.aws_region
    },
    {
      "name" : "AWS_STORAGE_BUCKET_NAME",
      "value" : "${local.prefix}-backend-media"
    },
    {
      "name" : "CORS_ALLOWED_ORIGINS",
      "value" : "https://${var.cf_domain},https://${module.alb.load_balancer_dns_name["lb"]}"
    },
    {
      "name" : "REACT_APP_SERVER_ENDPOINT",
      "value" : "https://${var.cf_domain}/api/v1"
    },
    {
      "name" : "DB_USER",
      "value" : local.db_iam_user_name
    },
    {
      "name" : "DB_HOST_PORT",
      "value" : module.db_default.db_instance_endpoint
    },
    {
      "name" : "DB_NAME",
      "value" : module.db_default.db_instance_name
    },
    {
      "name" : "DEPLOYMENT",
      "value" : "aws"
    },
    {
      "name" : "ENVIRONMENT",
      "value" : "production"
    },
    {
      "name" : "FRONTEND_DOMAIN",
      "value" : var.cf_domain
    },
    {
      "name" : "REGION",
      "value" : local.aws_region
    },
    {
      "name" : "STATIC_URL",
      "value" : "static_files/"
    },
    {
      "name" : "ECS_LOGLEVEL"
      "value" : "debug"
    },
    {
      "name" : "ENTREZ_SECRET_ARN",
      "value" : resource.aws_secretsmanager_secret.ncbi_entrez.arn
    },
    {
      "name" : "CLOUDWATCH_LOGGROUP_ADMIN",
      "value" : resource.aws_cloudwatch_log_group.django-admin.name
    },
    {
      "name" : "CLOUDWATCH_LOGGROUP_DELEGATE",
      "value" : resource.aws_cloudwatch_log_group.django-delegate.name
    },
    {
      "name" : "CLOUDWATCH_LOGGROUP_SERVER",
      "value" : resource.aws_cloudwatch_log_group.django-server.name
    }
  ]

  migrations_secret_environments = [
    {
      "name" : "SECRET_KEY"
      "valueFROM" : "${resource.aws_secretsmanager_secret.django.arn}:::${resource.aws_secretsmanager_secret_version.django.version_id}"
    }
  ]

  #Services
  ecs_services = {
    "${local.prefix}-backend" = {
      subnets = var.low_cost_implementation ? [module.vpc.public_subnets[0], module.vpc.public_subnets[1]] : [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
      security_groups = [
        module.sg.security_group_id["private-ecs"]
      ]
      task_definition                    = "${local.prefix}-backend"
      cluster                            = module.ecs.aws_ecs_cluster_name["cluster"]
      launch_type                        = "FARGATE"
      desired_count                      = 1
      deployment_maximum_percent         = 200
      deployment_minimum_healthy_percent = 100
      deployment_wait                    = 600
      assign_public_ip                   = var.low_cost_implementation
      load_balancers = {
        lb1 = {
          target_group_arn = module.alb.target_group_arn["lb-tg"]
          container_name   = "${local.prefix}-backend"
          container_port   = 8000
        }
      }
    }
  }
}
