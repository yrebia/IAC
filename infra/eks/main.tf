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
  region = var.region

  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_credentials_validation = true

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = var.project_id
      Env       = var.env
    }
  }
}

provider "aws" {
  alias  = "eks"
  region = var.region

  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_credentials_validation = true
}

##########################################
# Désactivation manuelle du data IAM
##########################################
# Patch pour éviter l'appel IAM:GetRole dans terraform-aws-modules/eks
# → On simule un contexte vide pour contourner le data source interne
data "aws_caller_identity" "current" {}

locals {
  fake_iam_session_context = {
    issuer_arn = "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/GitHubActionsRole"
    arn        = "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/GitHubActionsRole"
    user_id    = "GitHubActions"
  }
}

##########################################
# Module EKS (cluster)
##########################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.1"

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

  # Patch: ne pas utiliser encryption_config.provider_key_arn
  cluster_encryption_config = {}

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
