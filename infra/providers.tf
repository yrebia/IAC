##########################################
# Provider Kubernetes et Helm (connectés au cluster EKS)
##########################################

# 🔹 Récupère les infos du cluster EKS
data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

# 🔹 Récupère un token d’accès temporaire
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# 🔹 Provider Kubernetes configuré avec le cluster EKS
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# 🔹 Provider Helm configuré avec le cluster EKS
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
