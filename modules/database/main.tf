# 1. Database Subnet Group (spans DB Private Subnets across 2 AZs)
resource "aws_db_subnet_group" "db" {
  name        = "rds-subnet-group-${var.environment}"
  subnet_ids  = var.db_private_subnet_ids
  description = "Database private subnet group spanning 2 Availability Zones"

  tags = {
    Name        = "rds-subnet-group-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# 2. Security Group for Database Instance (Restricted Ingress)
resource "aws_security_group" "db" {
  name        = "rds-sg-${var.environment}"
  description = "Security group for RDS database instance with restricted access"
  vpc_id      = var.vpc_id

  # STRICT ZERO-TRUST RULE:
  # Inbound connection on port 5432 is strictly allowed from Backend EC2 SG only
  ingress {
    description     = "Allow PostgreSQL connection ONLY from Backend Security Group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.backend_security_group_id]
  }

  egress {
    description      = "Allow outbound response traffic within VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "rds-sg-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# 3. Amazon RDS PostgreSQL Instance
resource "aws_db_instance" "db" {
  identifier             = "rds-postgres-${var.environment}"
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  storage_type           = "gp3"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]

  # SECURITY REQUIREMENT: Database is NOT publicly accessible
  publicly_accessible     = false
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Name        = "rds-postgres-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}