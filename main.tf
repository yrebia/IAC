##########################################
# Helm release (namespace app déjà créé via namespace.tf)
##########################################
resource "helm_release" "task_manager" {
  name             = "task-manager"
  namespace        = "app"
  chart            = "${path.module}/charts/task-manager"
  create_namespace = false

  values = [file("${path.module}/charts/task-manager/values.yaml")]

  wait            = true
  timeout         = 600
  force_update    = true
  atomic          = true
  cleanup_on_fail = true

  depends_on = [
    kubernetes_namespace.app,
    kubernetes_secret.db
  ]
}

##########################################
# Réseau (VPC + Subnets)
##########################################
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags       = { Name = var.vpc_name }
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.subnet_az
  tags              = { Name = "${var.vpc_name}-subnet" }
}

resource "aws_subnet" "db" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_cidr
  availability_zone = var.db_subnet_az
  tags              = { Name = "${var.vpc_name}-db-subnet" }
}

##########################################
# RDS subnet group + Security Group + Instance
##########################################
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_id}-db-subnet-group"
  subnet_ids = [aws_subnet.main.id, aws_subnet.db.id]
}

# Security Group pour la DB (autorise EKS -> 5432)
resource "aws_security_group" "db" {
  name        = "${var.project_id}-db-sg"
  description = "Allow Postgres from EKS nodes"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "db_ingress_from_eks" {
  type              = "ingress"
  security_group_id = aws_security_group.db.id
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  # Réutilise le data source défini dans providers.tf
  source_security_group_id = data.aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "db_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.db.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_db_instance" "main" {
  identifier = "${var.project_id}-database"

  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  db_name  = var.db_name
  username = var.db_username

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  publicly_accessible = false
  skip_final_snapshot = true

  depends_on = [
    aws_security_group_rule.db_ingress_from_eks
  ]
}

##########################################
# Secret K8s pour l'app (à partir du Secret Manager RDS)
##########################################
data "aws_secretsmanager_secret_version" "db_master" {
  secret_id = aws_db_instance.main.master_user_secret[0].secret_arn
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
    DB_HOST      = aws_db_instance.main.address
    DB_PORT      = "5432"
    DB_NAME      = var.db_name
    DB_USER      = local.db_creds.username
    DB_PASSWORD  = local.db_creds.password
    DATABASE_URL = "postgresql://${local.db_creds.username}:${local.db_creds.password}@${aws_db_instance.main.address}:5432/${var.db_name}"
  }
  type = "Opaque"

  depends_on = [
    kubernetes_namespace.app,
    aws_db_instance.main
  ]
}
