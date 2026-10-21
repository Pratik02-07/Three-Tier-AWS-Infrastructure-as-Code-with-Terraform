variable "aws_region" {
  description = "AWS region for the S3 state backend and DynamoDB lock table"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique name for the S3 remote state bucket"
  type        = string
  default     = "three-tier-tf-state-backend-2026"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "three-tier-tf-locks"
}