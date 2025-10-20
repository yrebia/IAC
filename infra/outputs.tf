output "vpc_id" {
  description = "ID du VPC créé par le module network"
  value       = module.network.vpc_id
}

output "app_subnet_id" {
  description = "Subnet applicatif"
  value       = module.network.app_subnet_id
}

output "db_subnet_id" {
  description = "Subnet base de données"
  value       = module.network.db_subnet_id
}

output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_endpoint
}

output "db_secret_arn" {
  description = "ARN du secret contenant les credentials RDS"
  value       = module.database.db_secret_arn
  sensitive   = true
}

output "eks_cluster_name" {
  description = "Nom du cluster EKS"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint API du cluster EKS"
  value       = module.eks.cluster_endpoint
}
