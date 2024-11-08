module "alb" {
  source                  = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//elb?ref=elb-v1.0"
  load_balancers          = local.load_balancers
  environment             = var.environment
  module_name             = var.module_name
  project_name            = var.project_name
  target_groups           = local.target_groups
  load_balancer_listeners = local.load_balancer_listeners
  http_to_https           = local.http_to_https
  listener_rules          = local.listener_rules
}

locals {
  load_balancers = {
    lb = {
      name            = format("%s-lb", substr("${local.prefix}", 0, 26))
      subnets         = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
      type            = "application"
      security_groups = [module.sg.security_group_id["public-alb"]]
    }
  }
  target_groups = {
    lb-tg = {
      target_type            = "ip"
      name                   = format("%s-lb-tg", substr("${local.prefix}", 0, 26))
      vpc_id                 = module.vpc.vpc_id
      protocol               = "HTTP"
      port                   = 8000
      proxy_protocol_v2      = false
      hc_enabled             = true
      hc_healthy_threshold   = 3
      hc_interval            = 30
      hc_matcher             = "200"
      hc_path                = "/ping"
      hc_port                = 8000
      hc_protocol            = "HTTP"
      hc_timeout             = 5
      hc_unhealthy_threshold = 3
      deregistration_delay   = 300
    }
  }

  http_to_https = ["lb"]

  load_balancer_listeners = {
    lb-listener = {
      load_balancer        = "lb"
      port                 = 443
      protocol             = "HTTPS"
      ssl_policy           = "ELBSecurityPolicy-2016-08"
      certificate_arn      = data.aws_acm_certificate.main-region.arn
      default_target_group = "lb-tg"
    }
  }
  listener_rules = {
    lb-wildcard = {
      listener     = "lb-listener"
      target_group = "lb-tg"
      priority     = 100
      conditions = [
        {
          type   = "path_pattern"
          values = ["/*"]
        }
      ]
    }
  }
}
