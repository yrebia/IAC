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
data "aws_caller_identity" "current" {}

locals {
  fake_iam_session_context = {
    issuer_arn = "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/GitHubActionsRole"
    arn        = "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/GitHubActionsRole"
    user_id    = "GitHubActions"
  }
}

resource "aws_cloudwatch_log_group" "eks_cluster_logs" {
  name              = "/aws/eks/tmgr-eks/cluster"
  retention_in_days = 30

  lifecycle {
    ignore_changes = all
  }
}

##########################################
# Module EKS (cluster)
##########################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.1"
  depends_on = [aws_cloudwatch_log_group.eks_cluster_logs]

  providers = {
    aws = aws.eks
  }

  cluster_name    = var.cluster_name
  cluster_version = "1.31"
  vpc_id          = var.vpc_id
  subnet_ids = [
    "subnet-079476718bf99b770",
    "subnet-0b13d0ce97c312357"
  ]

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

  ##########################################
  # Node groups (pools)
  ##########################################
  eks_managed_node_groups = {
    apps = {
      desired_size   = 1
      min_size       = 1
      max_size       = 1
      instance_types = ["t3.micro"]
      capacity_type  = "ON_DEMAND"

      labels = {
        role = "app"
      }

      tags = {
        Name = "apps-nodegroup"
      }
    }

    # monitoring node group removed: monitoring is handled by the charts/monitoring Helm chart

    gha = {
      desired_size   = 1
      min_size       = 0
      max_size       = 1
      instance_types = ["t3.micro"]
      capacity_type  = "ON_DEMAND"

      labels = {
        role = "gha-runner"
      }

      tags = {
        Name = "gha-nodegroup"
      }
    }
  }
}

##########################################
# AWS Auth ConfigMap (Cluster Access)
##########################################

module "aws_auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.0"

  depends_on = [module.eks]

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${var.aws_account_id}:role/GitHubActionsRole"
      username = "github-actions"
      groups   = ["system:masters"]
    }
  ]
}
