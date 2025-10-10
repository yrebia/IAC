
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.main.id
}

output "db_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "RDS instance endpoint"
}

output "db_secret_arn" {
  value       = length(aws_db_instance.main.master_user_secret) > 0 ? aws_db_instance.main.master_user_secret[0].secret_arn : null
  description = "ARN du secret contenant les credentials de la base de données"
  sensitive   = true
}
