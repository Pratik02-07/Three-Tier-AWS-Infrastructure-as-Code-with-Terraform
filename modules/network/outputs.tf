output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "app_private_subnet_ids" {
  description = "List of IDs of the application private subnets"
  value       = aws_subnet.app_private[*].id
}

output "db_private_subnet_ids" {
  description = "List of IDs of the database private subnets"
  value       = aws_subnet.db_private[*].id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.nat.id
}