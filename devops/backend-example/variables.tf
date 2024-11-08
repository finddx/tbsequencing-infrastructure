# global
variable "project_name" {
  type        = string
  description = "Project name. Will be used for as prefix for naming resources."
}

variable "environment" {
  type        = string
  description = "Name of the environment to be deployed to. Will be used as prefix for naming resources."
}
