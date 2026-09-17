output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
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

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}
