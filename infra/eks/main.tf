##########################################
# Providers & Versions
##########################################
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "aws" {
  region = var.region
}

##########################################
# Lookups réseau (VPC + Subnets)
##########################################

# Recherche du VPC par Name + CIDR (fallback possible via var.vpc_id)
data "aws_vpcs" "by_name_cidr" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }

  filter {
    name   = "cidr-block"
    values = [var.cidr_block]
  }
}

locals {
  # Si vpc_id est renseigné, on l'utilise. Sinon, on cherche par tag/cidr.
  resolved_vpc_ids = var.vpc_id != "" ? [var.vpc_id] : data.aws_vpcs.by_name_cidr.ids
  existing_vpc_id  = element(local.resolved_vpc_ids, 0)
}

# Subnet "app" (subnet applicatif)
data "aws_subnets" "app" {
  filter {
    name   = "vpc-id"
    values = [local.existing_vpc_id]
  }
  filter {
    name   = "cidr-block"
    values = [var.subnet_cidr]
  }
}

# Subnet "db" (pour la base de données)
data "aws_subnets" "db_by_cidr" {
  filter {
    name   = "vpc-id"
    values = [local.existing_vpc_id]
  }
  filter {
    name   = "cidr-block"
    values = [var.db_subnet_cidr]
  }
}

# Fallback si le subnet DB n'est pas trouvé par CIDR
data "aws_subnets" "db_by_az" {
  filter {
    name   = "vpc-id"
    values = [local.existing_vpc_id]
  }
  filter {
    name   = "availability-zone"
    values = [var.db_subnet_az]
  }
}

locals {
  app_subnet_ids = var.subnet_id != "" ? [var.subnet_id] : data.aws_subnets.app.ids
  db_subnet_ids = var.db_subnet_id != "" ? [var.db_subnet_id] : (
    length(data.aws_subnets.db_by_cidr.ids) > 0 ? data.aws_subnets.db_by_cidr.ids : data.aws_subnets.db_by_az.ids
  )
  private_subnet_ids = [
    element(local.app_subnet_ids, 0),
    element(local.db_subnet_ids, 0)
  ]

  tags = merge(
    {
      Project     = var.project_id
      Environment = "dev"
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

##########################################
# Module EKS principal
##########################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = local.existing_vpc_id
  subnet_ids = local.private_subnet_ids

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = var.cluster_endpoint_public

  enable_irsa = true

  ##########################################
  # Add-ons EKS de base
  ##########################################
  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  ##########################################
  # Node Groups (3 pools)
  ##########################################
  eks_managed_node_groups = {
    # === Pool Applications ===
    apps = {
      instance_types = [var.apps_instance_type]
      min_size       = var.apps_min
      desired_size   = var.apps_desired
      max_size       = var.apps_max
      capacity_type  = var.apps_capacity_type
      labels         = { pool = "apps" }
    }

    # === Pool Monitoring (Prometheus / Grafana / OTel) ===
    monitoring = {
      instance_types = [var.monitoring_instance_type]
      min_size       = var.monitoring_min
      desired_size   = var.monitoring_desired
      max_size       = var.monitoring_max
      capacity_type  = var.monitoring_capacity_type
      labels         = { pool = "monitoring" }

      taints = [{
        key    = "pool"
        value  = "monitoring"
        effect = "NO_SCHEDULE"
      }]
    }

    # === Pool GitHub Actions (runners) ===
    gha = {
      instance_types = [var.gha_instance_type]
      min_size       = var.gha_min
      desired_size   = var.gha_desired
      max_size       = var.gha_max
      capacity_type  = var.gha_capacity_type
      labels         = { pool = "gha" }

      taints = [{
        key    = "pool"
        value  = "gha"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  tags = local.tags
}