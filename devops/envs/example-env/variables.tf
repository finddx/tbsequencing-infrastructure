# global
variable "project_name" {
  type        = string
  description = "Project name. Used as part of the prefix for naming all resources."
}

variable "module_name" {
  type        = string
  default     = "main"
  description = "Infrastructure module name. Used as part of the prefix for naming all resources."
}

variable "environment" {
  type        = string
  description = "Environment identifier. Used as part of the prefix for naming all resources."
}

# ecr 
variable "ecr_image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

variable "cf_domain" {
  type        = string
  description = "Final web address at which service will be available."
}

variable "no_reply_email" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "low_cost_implementation" {
  type    = bool
  default = true
}

variable "chatbot_notifs_implementation" {
  type    = bool
  default = false
}

variable "gh_action_roles" {
  type    = bool
  default = false
}

variable "cf_restrictions" {
  type = object({
    type      = string,
    locations = list(string)
    }
  )
  default = {
    type      = "none"
    locations = []
  }
}

variable "github_org_name" {
  type    = string
  default = ""
}

variable "github_repo_prefix" {
  type    = string
  default = ""
}
