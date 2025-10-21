##########################################
# Terraform Providers & Backend
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
# Network Lookups (VPC + Subnets)
##########################################
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
  resolved_vpc_ids = var.vpc_id != "" ? [var.vpc_id] : data.aws_vpcs.by_name_cidr.ids
  existing_vpc_id  = element(local.resolved_vpc_ids, 0)
}

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

data "aws_subnets" "db" {
  filter {
    name   = "vpc-id"
    values = [local.existing_vpc_id]
  }
  filter {
    name   = "cidr-block"
    values = [var.db_subnet_cidr]
  }
}

locals {
  private_subnet_ids = [
    element(data.aws_subnets.app.ids, 0),
    element(data.aws_subnets.db.ids, 0)
  ]

  tags = merge(
    {
      Project     = var.project_id
      Environment = var.env
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

##########################################
# EKS Cluster Module
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

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  eks_managed_node_groups = {
    apps = {
      instance_types = [var.apps_instance_type]
      min_size       = var.apps_min
      desired_size   = var.apps_desired
      max_size       = var.apps_max
      capacity_type  = var.apps_capacity_type
    }
  }

  tags = local.tags
}

##########################################
# EKS Access Configuration (IAM Integration)
##########################################
data "aws_caller_identity" "current" {}

# GitHub Actions
resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = module.eks.cluster_name
  principal_arn = var.github_actions_role_arn
  type          = "STANDARD"
  tags          = local.tags
}

resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = var.github_actions_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
}

# Étudiants
resource "aws_eks_access_entry" "students" {
  for_each      = { for u in var.students_usernames : u => u }
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${each.key}"
  type          = "STANDARD"
  tags          = local.tags
}

resource "aws_eks_access_policy_association" "students_admin" {
  for_each      = aws_eks_access_entry.students
  cluster_name  = module.eks.cluster_name
  principal_arn = each.value.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
}