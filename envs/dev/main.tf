terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "three-tier-tf-state-backend-2026"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "three-tier-tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "network" {
  source      = "../../modules/network"
  environment = var.environment
}

module "compute" {
  source                    = "../../modules/compute"
  environment               = var.environment
  vpc_id                    = module.network.vpc_id
  public_subnet_ids         = module.network.public_subnet_ids
  app_private_subnet_ids    = module.network.app_private_subnet_ids
  frontend_instance_type    = var.frontend_instance_type
  backend_instance_type     = var.backend_instance_type
  frontend_min_size         = var.frontend_min_size
  frontend_max_size         = var.frontend_max_size
  frontend_desired_capacity = var.frontend_desired_capacity
  backend_min_size          = var.backend_min_size
  backend_max_size          = var.backend_max_size
  backend_desired_capacity  = var.backend_desired_capacity
}

module "database" {
  source                    = "../../modules/database"
  environment               = var.environment
  vpc_id                    = module.network.vpc_id
  db_private_subnet_ids     = module.network.db_private_subnet_ids
  backend_security_group_id = module.compute.backend_security_group_id
  db_instance_class         = var.db_instance_class
  allocated_storage         = var.db_allocated_storage
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  multi_az                  = var.db_multi_az
}