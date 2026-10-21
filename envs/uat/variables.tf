variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "uat"
}

variable "frontend_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "backend_instance_type" {
  type    = string
  default = "t3.micro"
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

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "uatdb"
}

variable "db_username" {
  type    = string
  default = "uatadmin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_multi_az" {
  type    = bool
  default = false
}