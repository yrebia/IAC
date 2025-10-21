##########################################
# Terraform & Providers
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

  backend "s3" {}
}

provider "aws" {
  region = var.region
}

##########################################
# Module Network
##########################################
module "network" {
  source = "./network"

  vpc_name       = var.vpc_name
  cidr_block     = var.cidr_block
  subnet_cidr    = var.subnet_cidr
  db_subnet_cidr = var.db_subnet_cidr
  vpc_id         = var.vpc_id
}

##########################################
# Module Permissions (IAM & OIDC)
##########################################
module "permissions" {
  source = "./permissions"

  project_id = var.project_id
  env        = var.env
  region     = var.region

  students = [
    { username = "pauline", email = "pauline@epitech.eu", fullname = "Pauline Dupont" },
    { username = "yanis", email = "yanis@epitech.eu", fullname = "Yanis Benali" },
    { username = "aldric", email = "aldric@epitech.eu", fullname = "Aldric Martin" },
    { username = "mathieu", email = "mathieu@epitech.eu", fullname = "Mathieu Lambert" }
  ]
}

##########################################
# Module EKS (Cluster)
##########################################
module "eks" {
  source = "./eks"

  project_id   = var.project_id
  region       = var.region
  cluster_name = var.cluster_name
  env          = var.env

  # Permissions IAM
  github_actions_role_arn     = module.permissions.github_actions_role_arn
  students_access_key_ids     = module.permissions.students_access_key_ids
  students_secret_access_keys = module.permissions.students_secret_access_keys

  # Réseau
  vpc_name       = var.vpc_name
  cidr_block     = var.cidr_block
  subnet_cidr    = var.subnet_cidr
  subnet_az      = var.subnet_az
  db_subnet_cidr = var.db_subnet_cidr
  db_subnet_az   = var.db_subnet_az

  # Passage explicite des IDs réseau du module network
  vpc_id             = module.network.vpc_id
  subnet_id          = module.network.app_subnet_id
  db_subnet_id       = module.network.db_subnet_id
  students_usernames = module.permissions.students_usernames
}

##########################################
# Module Database (RDS)
##########################################
module "database" {
  source = "./database"

  project_id = var.project_id
  vpc_id     = module.network.vpc_id
  subnet_ids = [module.network.app_subnet_id, module.network.db_subnet_id]

  db_engine            = var.db_engine
  db_engine_version    = var.db_engine_version
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name              = var.db_name
  db_username          = var.db_username

  depends_on = [module.eks]
}

##########################################
# Namespace Kubernetes
##########################################
resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
  }

  depends_on = [module.eks]
}

##########################################
# Secret DB (depuis AWS Secrets Manager)
##########################################
data "aws_secretsmanager_secret_version" "db_master" {
  secret_id = module.database.db_secret_arn
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_master.secret_string)
}

resource "kubernetes_secret" "db" {
  metadata {
    name      = "task-manager-db"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    DB_HOST      = module.database.db_endpoint
    DB_PORT      = "5432"
    DB_NAME      = var.db_name
    DB_USER      = local.db_creds.username
    DB_PASSWORD  = local.db_creds.password
    DATABASE_URL = "postgresql://${local.db_creds.username}:${local.db_creds.password}@${module.database.db_endpoint}:5432/${var.db_name}"
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace.app,
    module.database
  ]
}

##########################################
# Helm Release (Chart Task Manager)
##########################################
resource "helm_release" "task_manager" {
  name             = "task-manager"
  namespace        = kubernetes_namespace.app.metadata[0].name
  chart            = "${path.module}/../charts/task-manager"
  create_namespace = false

  values = [file("${path.module}/../charts/task-manager/values.yaml")]

  wait            = true
  timeout         = 600
  force_update    = true
  atomic          = true
  cleanup_on_fail = true

  depends_on = [
    kubernetes_secret.db,
    module.eks
  ]
}