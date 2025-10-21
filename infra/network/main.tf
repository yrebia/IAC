##########################################
# Détermination du VPC
##########################################

# Si un VPC ID est fourni, on le prend directement
# Sinon, on fait un lookup par nom + CIDR
data "aws_vpcs" "by_name_cidr" {
  count = var.vpc_id == "" ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }

  filter {
    name   = "cidr-block"
    values = [var.cidr_block]
  }
}

# Local qui choisit intelligemment la bonne source
locals {
  resolved_vpc_id = var.vpc_id != "" ? var.vpc_id : try(data.aws_vpcs.by_name_cidr[0].id, null)
}

##########################################
# Subnets (app et db)
##########################################

# Subnet app
data "aws_subnets" "app" {
  count = local.resolved_vpc_id != null ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.resolved_vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = [var.subnet_cidr]
  }
}

# Subnet db
data "aws_subnets" "db" {
  count = local.resolved_vpc_id != null ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.resolved_vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = [var.db_subnet_cidr]
  }
}