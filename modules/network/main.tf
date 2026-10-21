# 1. Main VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "vpc-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "igw-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# 3. Public Subnets (across 2 AZs)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "public-subnet-${var.environment}-${count.index + 1}"
    Environment = var.environment
    Type        = "Public"
    ManagedBy   = "Terraform"
  }
}

# 4. Application Private Subnets (across 2 AZs)
resource "aws_subnet" "app_private" {
  count                   = length(var.app_private_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.app_private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "private-subnet-${var.environment}-${count.index + 1}"
    Environment = var.environment
    Type        = "Private-App"
    ManagedBy   = "Terraform"
  }
}

# 5. Database Private Subnets (across 2 AZs)
resource "aws_subnet" "db_private" {
  count                   = length(var.db_private_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.db_private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "db-subnet-${var.environment}-${count.index + 1}"
    Environment = var.environment
    Type        = "Private-DB"
    ManagedBy   = "Terraform"
  }
}

# 6. Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name        = "nat-eip-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# 7. NAT Gateway placed in Public Subnet 2 (10.0.16.0/24 - as per diagram)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[1].id

  tags = {
    Name        = "nat-gateway-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_internet_gateway.igw]
}

# 8. Public Route Table (0.0.0.0/0 -> IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "public-rtb-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 9. Private Route Table (0.0.0.0/0 -> NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name        = "private-rtb-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Associate App Private Subnets with Private Route Table
resource "aws_route_table_association" "app_private" {
  count          = length(aws_subnet.app_private)
  subnet_id      = aws_subnet.app_private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Associate DB Private Subnets with Private Route Table
resource "aws_route_table_association" "db_private" {
  count          = length(aws_subnet.db_private)
  subnet_id      = aws_subnet.db_private[count.index].id
  route_table_id = aws_route_table.private.id
}