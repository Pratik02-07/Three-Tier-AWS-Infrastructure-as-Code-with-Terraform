variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "availability_zones" {
  description = "List of Availability Zones for subnet deployment"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (2 AZs)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_private_subnet_cidrs" {
  description = "CIDR blocks for application private subnets (2 AZs)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "db_private_subnet_cidrs" {
  description = "CIDR blocks for database private subnets (2 AZs)"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}
