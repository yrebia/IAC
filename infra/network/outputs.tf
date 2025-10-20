output "vpc_id" {
  value = local.resolved_vpc_id
}

output "app_subnet_id" {
  value = try(data.aws_subnets.app[0].ids[0], null)
}

output "db_subnet_id" {
  value = try(data.aws_subnets.db[0].ids[0], null)
}
