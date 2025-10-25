terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Remote backend configuration for team collaboration
  # The bucket must be created manually before terraform init
  # Backend config is loaded via -backend-config flag to support multiple environments

  backend "s3" {
    # Configuration loaded from ../backends/{env}.config files
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.region

  # Default tags applied to all resources
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = var.env
      Project     = var.project_id
      Team        = "Student-Team14"
    }
  }
}

# Configure Kubernetes Provider
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Configure Helm Provider
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# Use the VPC module
module "vpc" {
  source = "./network"

  vpc_name                = var.vpc_name
  cidr_block              = var.cidr_block
  subnet_cidr_block       = var.subnet_cidr_block
  env                     = var.env
  project_id              = var.project_id
  map_public_ip_on_launch = true
}

# EKS Cluster Module - C4.md Implementation
module "eks" {
  source = "./eks"

  cluster_name = "${var.project_id}-${var.env}-cluster"
  env          = var.env
  project_id   = var.project_id
  # kubernetes_version = var.kubernetes_version

  # Use subnets from VPC module
  subnet_ids         = module.vpc.subnet_ids
  private_subnet_ids = module.vpc.subnet_ids

  # GitHub Runners configuration
  # runner_instance_types = var.runner_instance_types
  # runner_desired_size   = var.runner_desired_size
  # runner_max_size       = var.runner_max_size
  # runner_min_size       = var.runner_min_size

  # Application configuration
  # app_instance_types = var.app_instance_types
  # app_desired_size   = var.app_desired_size
  # app_max_size       = var.app_max_size
  # app_min_size       = var.app_min_size

  depends_on = [module.vpc]
}

# Database Module (RDS)
module "database" {
  source = "./database"

  project_id           = var.project_id
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.subnet_ids
  db_engine            = var.db_engine
  db_engine_version    = var.db_engine_version
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name              = var.db_name
  db_username          = var.db_username
  allowed_cidr_blocks  = module.vpc.subnet_cidr_blocks

  depends_on = [module.vpc]
}

# Namespace applicatif (existant)
data "kubernetes_namespace" "app" {
  metadata { name = "app" }
  # S'assure que le cluster est prêt avant la lecture
  depends_on = [module.eks]
}

# Récupération du mot de passe maître géré par AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_master" {
  secret_id = module.database.db_secret_arn
}

locals {
  db_master_secret = jsondecode(data.aws_secretsmanager_secret_version.db_master.secret_string)
  db_password = local.db_master_secret["password"]
  db_host     = split(":", chomp(module.database.db_endpoint))[0]
}

# Secret K8s attendu par le chart (HOST + PASSWORD)
resource "kubernetes_secret" "task_manager_db" {
  metadata {
    name      = "task-manager-db"
    namespace = "app"
  }
  data = {
    DATABASE_HOST     = local.db_host
    DATABASE_PASSWORD = local.db_password
  }
  type = "Opaque"

  depends_on = [
    module.database,
    helm_release.task_manager
  ]
}

# RDS Database Module - C4.md Implementation
# module "rds" {
#   source = "../modules/rds"

#   db_name      = "${var.project_name}-${var.environment}"
#   environment  = var.environment
#   project_name = var.project_name

#   vpc_id              = module.vpc.vpc_id
#   subnet_ids          = module.vpc.subnet_ids
#   allowed_cidr_blocks = [var.cidr_block]

#   postgres_version      = var.postgres_version
#   instance_class        = var.db_instance_class
#   allocated_storage     = var.db_allocated_storage
#   max_allocated_storage = var.db_max_allocated_storage

#   backup_retention_period = var.db_backup_retention_period
#   deletion_protection     = var.db_deletion_protection
#   skip_final_snapshot     = var.db_skip_final_snapshot

#   depends_on = [module.vpc]
# }

# Helm Releases - C4.md Implementation

# Deploy AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.2"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.eks.load_balancer_controller_role_arn
  }

  depends_on = [module.eks]
}

resource "aws_route53_zone" "main" {
  name = "student-team14.local"
}

resource "helm_release" "task_manager" {
  name       = "task-manager"
  chart      = "../charts/task-manager"
  namespace  = "app"

  create_namespace = true

  set {
    name = "db.name"
    value = var.db_name
  }

  set {
    name = "db.username"
    value = var.db_username
  }

  set {
    name = "db.port"
    value = var.db_port
  }

  set {
    name  = "db.useDatabaseUrl"
    value = "false"
  }

  depends_on = [
    module.eks,
    helm_release.aws_load_balancer_controller
  ]
}

data "kubernetes_service" "api" {
  metadata {
    name      = "api-service"      # Replace with your app's service name
    namespace = "app"              # Replace with your app's namespace
  }
  depends_on = [helm_release.task_manager] # or your app's Helm release resource
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.id
  name    = "api-${var.env}"
  type    = "CNAME"
  ttl     = 300
  records = [data.kubernetes_service.api.status[0].load_balancer[0].ingress[0].hostname]
  depends_on = [data.kubernetes_service.api]
}
