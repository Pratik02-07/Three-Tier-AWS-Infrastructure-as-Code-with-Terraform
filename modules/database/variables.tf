variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where database resources are deployed"
  type        = string
}

variable "db_private_subnet_ids" {
  description = "Database private subnet IDs (must span at least 2 AZs)"
  type        = list(string)
}

variable "backend_security_group_id" {
  description = "Security group ID of the Backend App tier for restricted ingress"
  type        = string
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.7"
}

variable "db_instance_class" {
  description = "RDS DB Instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage size in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage limit in GB for autoscaling"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master database username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Master database password"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 1
}