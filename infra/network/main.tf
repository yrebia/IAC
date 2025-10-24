# VPC Module - Demonstrates Terraform Principles from C1.md
# This module implements Reproducibility, Idempotence, and Versioning

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = var.vpc_name
    Environment = var.env
    Project     = var.project_id
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "main" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name        = "${var.vpc_name}-subnet-${count.index + 1}"
    Environment = var.env
    Project     = var.project_id
    ManagedBy   = "Terraform"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.vpc_name}-igw"
    Environment = var.env
    Project     = var.project_id
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.vpc_name}-rt"
    Environment = var.env
    Project     = var.project_id
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table_association" "main" {
  count          = 1  # Only subnet[0] is public
  subnet_id      = aws_subnet.main[count.index].id
  route_table_id = aws_route_table.main.id
}

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.main[0].id # Use your public subnet (usually index 0)
  depends_on    = [aws_eip.nat]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.main[1].id # Use your private subnet (usually index 1)
  route_table_id = aws_route_table.private.id
}
