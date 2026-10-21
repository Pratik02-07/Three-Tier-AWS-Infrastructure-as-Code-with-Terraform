variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "frontend_instance_type" {
  type    = string
  default = "t3.small"
}

variable "backend_instance_type" {
  type    = string
  default = "t3.small"
}

variable "frontend_min_size" {
  type    = number
  default = 2
}

variable "frontend_max_size" {
  type    = number
  default = 6
}

variable "frontend_desired_capacity" {
  type    = number
  default = 4
}

variable "backend_min_size" {
  type    = number
  default = 2
}

variable "backend_max_size" {
  type    = number
  default = 6
}

variable "backend_desired_capacity" {
  type    = number
  default = 4
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.small"
}

variable "db_allocated_storage" {
  type    = number
  default = 50
}

variable "db_name" {
  type    = string
  default = "proddb"
}

variable "db_username" {
  type    = string
  default = "prodadmin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_multi_az" {
  type        = bool
  description = "Multi-AZ synchronous replication across AZ-a and AZ-b"
  default     = true
}