resource "kubernetes_namespace" "app" {
  metadata { name = "app" }
}

resource "helm_release" "task_manager" {
  name             = "task-manager"
  namespace        = kubernetes_namespace.app.metadata[0].name
  chart            = "${path.module}/charts/task-manager"
  create_namespace = false

  values = [file("${path.module}/charts/task-manager/values.yaml")]

  wait         = true
  timeout      = 600
  force_update = true
  atomic          = true
  cleanup_on_fail = true
}

