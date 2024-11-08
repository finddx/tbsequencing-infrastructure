output "cloudfront_distribution_id" {
  value = module.cloudfront.distribution_id
}

output "cloudfront_distribution_domain_name" {
  value = module.cloudfront.distribution_domain
}

output "elb_dns" {
  value = module.alb.load_balancer_dns_name["lb"]
}

output "database_url" {
  value = module.db_default.db_instance_endpoint
}

output "db_host" {
  value = module.db_default.db_instance_address
}
