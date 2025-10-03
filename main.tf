# --- K8s namespace + Helm release ---
resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
  }
}

resource "helm_release" "task_manager" {
  name             = "task-manager"
  namespace        = kubernetes_namespace.app.metadata[0].name
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

# --- Outputs ---
output "vpc_id" { value = aws_vpc.main.id }
output "subnet_id" { value = aws_subnet.main.id }
