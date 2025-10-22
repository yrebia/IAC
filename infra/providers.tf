data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.this.endpoint, null)
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.this.certificate_authority[0].data), null)
  token                  = try(data.aws_eks_cluster_auth.this.token, null)
}

provider "helm" {
  kubernetes {
    host                   = try(data.aws_eks_cluster.this.endpoint, null)
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.this.certificate_authority[0].data), null)
    token                  = try(data.aws_eks_cluster_auth.this.token, null)
  }
}
