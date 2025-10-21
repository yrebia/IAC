output "vpc_id" {
  value       = module.network.vpc_id
  description = "VPC ID"
}

output "app_subnet_id" {
  value       = module.network.app_subnet_id
  description = "App subnet"
}

output "db_subnet_id" {
  value       = module.network.db_subnet_id
  description = "DB subnet"
}

output "db_endpoint" {
  value       = module.database.db_endpoint
  description = "RDS endpoint"
}

output "db_secret_arn" {
  value       = module.database.db_secret_arn
  sensitive   = true
  description = "ARN du secret DB"
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "Nom du cluster EKS"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Endpoint API du cluster EKS"
}
