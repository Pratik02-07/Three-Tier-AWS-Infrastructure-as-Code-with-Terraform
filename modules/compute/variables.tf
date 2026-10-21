variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where compute resources reside"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public Subnet IDs for ALB and Frontend ASG placement"
  type        = list(string)
}

variable "app_private_subnet_ids" {
  description = "Private Subnet IDs for Backend ASG placement"
  type        = list(string)
}

variable "frontend_instance_type" {
  description = "Instance type for frontend EC2 instances"
  type        = string
  default     = "t3.micro"
}

variable "backend_instance_type" {
  description = "Instance type for backend EC2 instances"
  type        = string
  default     = "t3.micro"
}

variable "frontend_min_size" {
  description = "Minimum capacity for Frontend ASG"
  type        = number
  default     = 1
}

variable "frontend_max_size" {
  description = "Maximum capacity for Frontend ASG"
  type        = number
  default     = 3
}

variable "frontend_desired_capacity" {
  description = "Desired capacity for Frontend ASG"
  type        = number
  default     = 2
}

variable "backend_min_size" {
  description = "Minimum capacity for Backend ASG"
  type        = number
  default     = 1
}

variable "backend_max_size" {
  description = "Maximum capacity for Backend ASG"
  type        = number
  default     = 3
}

variable "backend_desired_capacity" {
  description = "Desired capacity for Backend ASG"
  type        = number
  default     = 2
}