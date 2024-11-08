data "aws_caller_identity" "current" {}

data "aws_ami" "amazon_linux_2_latest" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["amazon"]
}

data "aws_secretsmanager_secret" "ms_teams" {
  count = var.chatbot_notifs_implementation ? 1 : 0
  name  = "ms-teams"
}

data "aws_secretsmanager_secret_version" "ms_teams_current" {
  count     = var.chatbot_notifs_implementation ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.ms_teams[0].id
}

data "aws_acm_certificate" "main-region" {
  domain = var.cf_domain
}

data "aws_acm_certificate" "us-east-1" {
  count    = var.aws_region != "us-east-1" ? 1 : 0
  domain   = var.cf_domain
  provider = aws.useast1
}
