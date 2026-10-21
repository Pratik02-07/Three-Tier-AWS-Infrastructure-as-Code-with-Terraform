output "db_instance_endpoint" {
  description = "The connection endpoint for the RDS database instance"
  value       = aws_db_instance.db.endpoint
}

output "db_instance_id" {
  description = "The RDS instance identifier"
  value       = aws_db_instance.db.id
}

output "db_instance_port" {
  description = "The port the database is listening on"
  value       = aws_db_instance.db.port
}

output "db_security_group_id" {
  description = "The ID of the database security group"
  value       = aws_security_group.db.id
}