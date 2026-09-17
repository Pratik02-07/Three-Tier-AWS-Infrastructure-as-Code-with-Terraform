variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources are deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB placement"
  type        = list(string)
}

variable "app_private_subnet_ids" {
  description = "Private subnet IDs for ASG EC2 instance placement"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 Instance type"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Application listening port"
  type        = number
  default     = 80
}

variable "min_size" {
  description = "Minimum capacity for ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum capacity for ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired capacity for ASG"
  type        = number
  default     = 2
}
