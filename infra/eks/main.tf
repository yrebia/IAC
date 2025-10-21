##########################################
# Terraform & Provider AWS
##########################################
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

##########################################
# Providers AWS (désactivation des appels IAM)
##########################################
provider "aws" {
  region                      = var.region
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_credentials_validation = true

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = var.project_id
      Env       = "dev"
    }
  }
}

provider "aws" {
  alias                       = "eks"
  region                      = var.region
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_credentials_validation = true
}

##########################################
# Module EKS (cluster)
##########################################
module "eks" {
  source                    = "terraform-aws-modules/eks/aws"
  version                   = "20.24.1"
  cluster_encryption_config = {}


  providers = {
    aws = aws.eks
  }

  cluster_name                   = var.cluster_name
  cluster_version                = "1.31"
  vpc_id                         = var.vpc_id
  subnet_ids                     = [var.subnet_id]
  cluster_endpoint_public_access = true
  enable_irsa                    = false
  create_kms_key                 = false

  tags = {
    Project     = var.project_id
    Environment = var.env
    ManagedBy   = "Terraform"
  }

  eks_managed_node_groups = {
    apps = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["t3.medium"]
    }
  }
}

##########################################
# EKS Access Entries + Policies
##########################################
# GitHub Actions
resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = module.eks.cluster_name
  principal_arn = var.github_actions_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = var.github_actions_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# Étudiants
resource "aws_eks_access_entry" "students" {
  for_each      = { for s in var.students : s.username => s }
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::${var.aws_account_id}:user/${each.value.username}"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "students_view" {
  for_each      = { for s in var.students : s.username => s }
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::${var.aws_account_id}:user/${each.value.username}"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type = "cluster"
  }
}

##########################################
# Outputs
##########################################
output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "app_subnet_id" {
  value = var.subnet_id
}

output "db_subnet_id" {
  value = var.db_subnet_id
}

output "github_actions_role_arn" {
  value = var.github_actions_role_arn
}

output "students_access_keys" {
  value     = null
  sensitive = true
}
