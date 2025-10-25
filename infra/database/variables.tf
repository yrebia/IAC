variable "project_id" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }

variable "db_engine" { type = string }
variable "db_engine_version" { type = string }
variable "db_instance_class" { type = string }
variable "db_allocated_storage" { type = number }
variable "db_name" { type = string }
variable "db_username" { type = string }

variable "allowed_cidr_blocks" {
	description = "CIDRs autorisés à se connecter à Postgres"
	type        = list(string)
}
