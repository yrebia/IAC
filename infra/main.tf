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
# Locals - Safe reference for permissions
##########################################
locals {
  github_actions_role_arn = (
    var.enable_permissions && length(module.permissions_enabled) > 0
  ) ? module.permissions_enabled[0].github_actions_role_arn : null
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
# Module EKS (Cluster)
##########################################
module "eks" {
  source = "./eks"

  project_id   = var.project_id
  region       = var.region
  cluster_name = var.cluster_name
  env          = var.env

  # Permissions IAM (optionnelles)
  github_actions_role_arn = local.github_actions_role_arn
  students                = var.students
  aws_account_id          = var.aws_account_id

  # Réseau
  vpc_id       = module.network.vpc_id
  subnet_id    = module.network.app_subnet_id
  db_subnet_id = module.network.db_subnet_id
}

##########################################
# Attente que le cluster EKS soit prêt
##########################################
resource "time_sleep" "wait_for_eks" {
  depends_on      = [module.eks]
  create_duration = "180s"
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
# Namespaces Kubernetes
##########################################
resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
  }
  depends_on = [time_sleep.wait_for_eks]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
  depends_on = [time_sleep.wait_for_eks]
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
    module.database,
    time_sleep.wait_for_eks
  ]
}

##########################################
# Helm Releases
##########################################

# Déploiement du chart de monitoring
resource "helm_release" "monitoring" {
  name      = "monitoring"
  chart     = "${path.module}/../charts/monitoring"
  namespace = kubernetes_namespace.monitoring.metadata[0].name

  values = [file("${path.module}/../charts/monitoring/values.yaml")]

  wait            = true
  timeout         = 600
  force_update    = true
  atomic          = true
  cleanup_on_fail = true

  depends_on = [
    module.eks,
    kubernetes_namespace.monitoring,
    time_sleep.wait_for_eks
  ]
}

# Déploiement du chart Task Manager
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
    module.eks,
    kubernetes_secret.db,
    time_sleep.wait_for_eks
  ]
}

##########################################
# ServiceMonitor pour scraper l'app
##########################################
resource "kubernetes_manifest" "task_manager_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "task-manager-metrics"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        app = "task-manager"
      }
    }
    spec = {
      namespaceSelector = {
        matchNames = [kubernetes_namespace.app.metadata[0].name]
      }
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "task-manager"
        }
      }
      endpoints = [{
        port     = "http"
        path     = "/metrics"
        interval = "30s"
      }]
    }
  }

  depends_on = [
    module.eks,
    helm_release.monitoring,
    helm_release.task_manager,
    time_sleep.wait_for_eks
  ]
}

##########################################
# Dashboard Grafana pour Task Manager
##########################################
/* Dashboard inclus dans le chart Helm "monitoring" */

##########################################
# Module Permissions (facultatif)
##########################################
module "permissions_enabled" {
  source = "./permissions"

  count = var.enable_permissions ? 1 : 0

  project_id     = var.project_id
  env            = var.env
  region         = var.region
  aws_account_id = var.aws_account_id

  students = [
    { username = "student1" },
    { username = "student2" },
    { username = "student3" },
    { username = "student4" }
  ]
}
