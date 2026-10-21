variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Compute Variables
variable "frontend_instance_type" {
  description = "Instance type for frontend web servers"
  type        = string
  default     = "t3.micro"
}

variable "backend_instance_type" {
  description = "Instance type for backend app servers"
  type        = string
  default     = "t3.micro"
}

variable "frontend_min_size" {
  type    = number
  default = 1
}

variable "frontend_max_size" {
  type    = number
  default = 3
}

variable "frontend_desired_capacity" {
  type    = number
  default = 2
}

variable "backend_min_size" {
  type    = number
  default = 1
}

variable "backend_max_size" {
  type    = number
  default = 3
}

variable "backend_desired_capacity" {
  type    = number
  default = 2
}

# Database Variables
variable "db_instance_class" {
  description = "RDS DB Instance Class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for DB (GB)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "devdb"
}

variable "db_username" {
  description = "Master database username"
  type        = string
  default     = "devadmin"
}

variable "db_password" {
  description = "Master database password"
  type        = string
  sensitive   = true
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for database"
  type        = bool
  default     = false
}