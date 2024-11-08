module "cloudfront" {
  source                = "git::https://github.com/finddx/seq-treat-tbkb-terraform-modules.git//cloudfront?ref=cf-v1.8"
  https_certificate_arn = var.aws_region == "us-east-1" ? data.aws_acm_certificate.main-region.arn : data.aws_acm_certificate.us-east-1[0].arn
  dns_name              = var.cf_domain
  elb_dns_name          = module.alb.load_balancer_dns_name["lb"]
  frontend_port         = 80
  frontend_ssl_port     = 443
  waf_web_acl_id        = var.low_cost_implementation ? null : module.waf[0].web_acl_arn
  restrictions          = var.cf_restrictions
  project_name          = var.project_name
  module_name           = var.module_name
  environment           = var.environment
}
