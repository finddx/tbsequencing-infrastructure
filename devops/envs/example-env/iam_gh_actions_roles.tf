resource "aws_iam_openid_connect_provider" "this" {
  count          = var.gh_action_roles ? 1 : 0
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
  tags = merge({ "Name" = "github-actions-integration" }, local.tags)
}

data "aws_iam_policy_document" "oidc_policy" {
  for_each = local.repo_mappings
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.this[0].arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = each.value.repos
    }
  }
}

locals {
  repo_mappings = var.gh_action_roles ? {
    "my-github-actions-frontend" = {
      repos = [
        "repo:${var.github_org_name}/${var.github_repo_prefix}-frontend:environment:${var.environment}"
      ]
    }
    "my-github-actions-backend" = {
      repos = [
        "repo:${var.github_org_name}/${var.github_repo_prefix}-backend:environment:${var.environment}"
      ]
    }
    "my-github-actions-push-glue" = {
      repos = [
        "repo:${var.github_org_name}/${var.github_repo_prefix}-bioinfoanalysis:environment:${var.environment}",
        "repo:${var.github_org_name}/${var.github_repo_prefix}-antimalware:environment:${var.environment}",
        "repo:${var.github_org_name}/${var.github_repo_prefix}-ncbi-sync:environment:${var.environment}",
        "repo:${var.github_org_name}/${var.github_repo_prefix}-backend:environment:${var.environment}"
      ]
    },
    "my-github-actions-terraform" = {
      repos = [
        "repo:${var.github_org_name}/${var.github_repo_prefix}-bioinfoanalysis:environment:${var.environment}",
        "repo:${var.github_org_name}/${var.github_repo_prefix}-infrastructure:environment:${var.environment}",
        "repo:${var.github_org_name}/${var.github_repo_prefix}-ncbi-sync:environment:${var.environment}",
      ]
    }
  } : {}

  policies_gh = var.gh_action_roles ? [
    {
      name        = "backend-static-s3"
      description = ""
      policy      = data.aws_iam_policy_document.backend-static-s3[0].json
    },
    {
      name        = "frontend-static-s3"
      description = ""
      policy      = data.aws_iam_policy_document.frontend-static-s3[0].json
    },
    {
      name        = "glue-scripts-s3"
      description = ""
      policy      = data.aws_iam_policy_document.glue-scripts-s3[0].json
    },
    {
      name        = "read-ecs-logs"
      description = ""
      policy      = data.aws_iam_policy_document.backend-read-ecs-logs[0].json
    },
    {
      name        = "allow-distribution-invalidation"
      description = ""
      policy      = data.aws_iam_policy_document.allow-distribution-invalidation[0].json
    },
    {
      name        = "get-tag-resources"
      description = ""
      policy      = data.aws_iam_policy_document.get-tag-resources[0].json
    },
  ] : []

  policy_mapping_gh = var.gh_action_roles ? {
    backend-static = {
      role   = module.roles-gh-actions[0].role_name["my-github-actions-backend"]
      policy = module.policies-gh-actions[0].policy_arn["backend-static-s3"]
    }
    backend-logs = {
      role   = module.roles-gh-actions[0].role_name["my-github-actions-backend"]
      policy = module.policies-gh-actions[0].policy_arn["read-ecs-logs"]
    }
    backend-invalidate = {
      role   = module.roles-gh-actions[0].role_name["my-github-actions-backend"]
      policy = module.policies-gh-actions[0].policy_arn["allow-distribution-invalidation"]
    }
    backend-tag = {
      role   = module.roles-gh-actions[0].role_name["my-github-actions-backend"]
      policy = module.policies-gh-actions[0].policy_arn["get-tag-resources"]
    }
    backend-ecs = {
      role   = module.roles-gh-actions[0].role_name["my-github-actions-backend"]
      policy = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
    }
    backend-ecr = {
      role   = module.roles-gh-actions[0].role_name["my-github-actions-backend"]
      policy = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
    }
    frontend-static = {
      role   = module.roles-gh-actions[0].role_name["my-github-actions-frontend"]
      policy = module.policies-gh-actions[0].policy_arn["frontend-static-s3"]
    }
    frontend-invalidate = {
      role   = module.roles-gh-actions[0].role_name["my-github-actions-frontend"]
      policy = module.policies-gh-actions[0].policy_arn["allow-distribution-invalidation"]
    }
    frontend-tag = {
      role   = module.roles-gh-actions[0].role_name["my-github-actions-frontend"]
      policy = module.policies-gh-actions[0].policy_arn["get-tag-resources"]
    }
    glue-s3 = {
      role   = module.roles-gh-actions[0].role_name["my-github-actions-push-glue"]
      policy = module.policies-gh-actions[0].policy_arn["glue-scripts-s3"]
    }
    glue-ecr = {
      role   = module.roles-gh-actions[0].role_name["my-github-actions-push-glue"]
      policy = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
    }
    terraform-admin = {
      role   = module.roles-gh-actions[0].role_name["my-github-actions-terraform"]
      policy = "arn:aws:iam::aws:policy/AdministratorAccess"
    }
  } : {}

  roles_gh = var.gh_action_roles ? [
    {
      name                    = "my-github-actions-frontend"
      instance_profile_enable = null
      custom_trust_policy     = data.aws_iam_policy_document.oidc_policy["my-github-actions-frontend"].json
    },
    {
      name                    = "my-github-actions-backend"
      instance_profile_enable = null
      custom_trust_policy     = data.aws_iam_policy_document.oidc_policy["my-github-actions-backend"].json
    },
    {
      name                    = "my-github-actions-push-glue"
      instance_profile_enable = null
      custom_trust_policy     = data.aws_iam_policy_document.oidc_policy["my-github-actions-push-glue"].json
    },
    {
      name                    = "my-github-actions-terraform"
      instance_profile_enable = null
      custom_trust_policy     = data.aws_iam_policy_document.oidc_policy["my-github-actions-terraform"].json
    },
  ] : []
}

module "policies-gh-actions" {
  count        = var.gh_action_roles ? 1 : 0
  source       = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//iam_policy?ref=iam_policy-v1.0"
  aws_region   = local.aws_region
  environment  = var.environment
  project_name = var.project_name
  module_name  = var.module_name
  policies     = local.policies_gh
}

module "policy_mapping-gh-actions" {
  count      = var.gh_action_roles ? 1 : 0
  source     = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//iam_policy_mapping?ref=iam_policy_mapping-v1.0"
  aws_region = local.aws_region
  roles      = local.policy_mapping_gh
}

module "roles-gh-actions" {
  count        = var.gh_action_roles ? 1 : 0
  source       = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//iam_role?ref=iam_role-v1.0"
  aws_region   = local.aws_region
  environment  = var.environment
  project_name = var.project_name
  module_name  = var.module_name
  roles        = local.roles_gh
}
