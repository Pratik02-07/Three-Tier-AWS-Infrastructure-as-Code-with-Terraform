# Database Subnet Group (spans DB Private Subnets across 2 AZs)
resource "aws_db_subnet_group" "db" {
  name        = "${var.environment}-db-subnet-group"
  subnet_ids  = var.db_private_subnet_ids
  description = "Database private subnet group spanning 2 Availability Zones"

  tags = {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Security Group for Database Instance
resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
  description = "Security group for RDS database instance with restricted access"
  vpc_id      = var.vpc_id

  # DELIBERATE ARCHITECTURAL DECISION:
  # Inbound connection is strictly restricted to traffic originating from the Application Security Group (var.app_security_group_id).
  # Under NO circumstances is port 5432 / 3306 exposed to 0.0.0.0/0 or any external public CIDR block.
  ingress {
    description     = "Allow DB connection ONLY from Application Security Group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
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
    Name        = "${var.environment}-db-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# RDS Postgres Database Instance
resource "aws_db_instance" "db" {

  identifier             = "${var.environment}-rds-db"
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.allocated_storage
  storage_type           = "gp3"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]

  # SECURITY REQUIREMENT: Database is NOT publicly accessible
  publicly_accessible = false
  multi_az            = var.multi_az
  skip_final_snapshot = true

  tags = {
    Name        = "${var.environment}-rds-instance"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
