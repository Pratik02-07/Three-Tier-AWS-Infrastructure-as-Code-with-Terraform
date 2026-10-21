variable "environment" {
  description = "Deployment environment name (dev, uat, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones to span across for high availability"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for Public Subnets (ALB & NAT Gateway)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.16.0/24"]
}

variable "app_private_subnet_cidrs" {
  description = "CIDR blocks for Application Private Subnets (App EC2 ASG)"
  type        = list(string)
  default     = ["10.0.24.0/24", "10.0.48.0/24"]
}

variable "db_private_subnet_cidrs" {
  description = "CIDR blocks for Database Private Subnets (RDS PostgreSQL)"
  type        = list(string)
  default     = ["10.0.64.0/24", "10.0.96.0/24"]
}