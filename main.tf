# --- Helm release (namespace app déjà créé hors TF) ---
resource "helm_release" "task_manager" {
  name             = "task-manager"
  namespace        = "app"
  chart            = "${path.module}/charts/task-manager"
  create_namespace = false

  values = [
    file("${path.module}/charts/task-manager/values.yaml")
  ]

  wait            = true
  timeout         = 600
  force_update    = true
  atomic          = true
  cleanup_on_fail = true
}

# --- Réseau (VPC + Subnet) ---
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

  tags = {
    Name = "${var.vpc_name}-db-subnet"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_id}-db-subnet-group"
  subnet_ids = [aws_subnet.main.id, aws_subnet.db.id]
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

  db_subnet_group_name = aws_db_subnet_group.main.name
  publicly_accessible  = false
  skip_final_snapshot  = true
}
