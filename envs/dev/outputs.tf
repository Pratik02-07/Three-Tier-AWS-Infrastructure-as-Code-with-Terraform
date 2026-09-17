output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS Name"
  value       = module.compute.alb_dns_name
}

output "db_endpoint" {
  description = "RDS Database Endpoint"
  value       = module.database.db_instance_endpoint
}
