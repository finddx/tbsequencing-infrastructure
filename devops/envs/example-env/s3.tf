module "s3" {
  source       = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//s3?ref=s3-v1.9"
  s3_buckets   = local.s3_bucket_names
  environment  = var.environment
  project_name = var.project_name
  module_name  = var.module_name
  tags         = local.tags
}

locals {
  s3_bucket_names = {
    backend-media = {
      enable_versioning   = true
      bucket_acl          = false
      enable_cors         = true
      enable_policy       = false
      bucket_owner_acl    = false
      policy              = null
      enable_notification = true
      cors_rule = [{
        allowed_headers = ["Authorization"],
        allowed_methods = [
          "GET",
          "POST"
        ],
        allowed_origins = [
          "*"
        ]
        }
      ]
    },
    backend-sequence-data = {
      enable_versioning = false
      bucket_acl        = false
      enable_cors       = true
      enable_policy     = false
      bucket_owner_acl  = false
      policy            = null
      cors_rule = [{
        allowed_headers = ["*"],
        allowed_methods = [
          "DELETE",
          "POST",
          "PUT"
        ],
        allowed_origins = [
          # Do not allow localhost for production environments
          # "http://localhost:3000",
          "https://${var.cf_domain}"
        ]
        },
        {
          allowed_headers = []
          allowed_methods = [
            "GET"
          ]
          allowed_origins = [
            "*"
          ]
        },
        {
          allowed_headers = ["Authorization"],
          allowed_methods = [
            "GET",
            "POST"
          ],
          allowed_origins = [
            "*"
          ]
        }
      ]
      enable_notification = true
    },
    glue-scripts = {
      enable_versioning   = true
      bucket_acl          = false
      enable_cors         = false
      enable_policy       = false
      bucket_owner_acl    = false
      policy              = null
      cors_rule           = []
      enable_notification = false
    }
  }
}
