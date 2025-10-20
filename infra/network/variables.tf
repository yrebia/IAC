variable "vpc_name" {
  type        = string
  description = "Nom du VPC existant"
}

variable "cidr_block" {
  type        = string
  description = "CIDR du VPC"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR du subnet applicatif"
}

variable "db_subnet_cidr" {
  type        = string
  description = "CIDR du subnet base de données"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID (si défini, le lookup est ignoré)"
  default     = ""
}
