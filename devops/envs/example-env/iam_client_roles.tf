locals {
  policies = [
    {
      name        = "rds_access"
      description = ""
      policy      = data.aws_iam_policy_document.rds_access.json
    },
    {
      name        = "fargate-execution-policy"
      description = ""
      policy      = data.aws_iam_policy_document.fargate_execution.json
    },
    {
      name        = "fargate-task-policy"
      description = ""
      policy      = data.aws_iam_policy_document.fargate_task.json
    },
    {
      name        = "step-function-executions-policy"
      description = ""
      policy      = data.aws_iam_policy_document.step_function_executions.json
    },
    {
      name        = "glue-executions-policy"
      description = ""
      policy      = data.aws_iam_policy_document.glue_executions.json
    },
  ]

  policy_mapping = {
    ecs_task_execution_role = {
      role   = module.roles.role_name["fargate-execution"]
      policy = module.policies.policy_arn["fargate-execution-policy"]
    }
    fargate_task = {
      role   = module.roles.role_name["fargate-task"]
      policy = module.policies.policy_arn["fargate-task-policy"]
    }
    rds_access = {
      role   = module.roles.role_name["fargate-task"]
      policy = module.policies.policy_arn["rds_access"]
    }
    bastion_role_attachment = {
      role   = module.roles.role_name["ec2"]
      policy = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
    bastion_step_function = {
      role   = module.roles.role_name["ec2"]
      policy = module.policies.policy_arn["step-function-executions-policy"]
    }
    bastion_glue = {
      role   = module.roles.role_name["ec2"]
      policy = module.policies.policy_arn["glue-executions-policy"]
    }
  }

  roles = [
    {
      name                    = "ec2"
      instance_profile_enable = true
      instance_profile_name   = "${local.prefix}-amazon-linux-2"
      custom_trust_policy     = data.aws_iam_policy_document.ec2_role.json
    },
    {
      name                    = "fargate-execution"
      instance_profile_enable = null
      custom_trust_policy     = data.aws_iam_policy_document.fargate-role-policy.json
    },
    {
      name                    = "fargate-task"
      instance_profile_enable = null
      custom_trust_policy     = data.aws_iam_policy_document.fargate-role-policy.json
    },
    {
      name                    = "lambda"
      instance_profile_enable = null
      custom_trust_policy     = data.aws_iam_policy_document.lambda_role.json
    },
  ]
}

module "policies" {
  source       = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//iam_policy?ref=iam_policy-v1.0"
  aws_region   = local.aws_region
  environment  = var.environment
  project_name = var.project_name
  module_name  = var.module_name
  policies     = local.policies
}

module "policy_mapping" {
  source     = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//iam_policy_mapping?ref=iam_policy_mapping-v1.0"
  aws_region = local.aws_region
  roles      = local.policy_mapping
}

module "roles" {
  source       = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//iam_role?ref=iam_role-v1.0"
  aws_region   = local.aws_region
  environment  = var.environment
  project_name = var.project_name
  module_name  = var.module_name
  roles        = local.roles
}

resource "aws_iam_service_linked_role" "chatbot" {
  aws_service_name = "management.chatbot.amazonaws.com"
}
