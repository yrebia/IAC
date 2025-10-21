variable "project_id" {
  type        = string
  description = "Project identifier"
}

variable "env" {
  type        = string
  description = "Environment (e.g., dev, prod)"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "vpc_name" {
  type        = string
  description = "VPC name tag"
}

variable "cidr_block" {
  type        = string
  description = "VPC CIDR block"
}

variable "subnet_cidr" {
  type        = string
  description = "Application subnet CIDR"
}

variable "db_subnet_cidr" {
  type        = string
  description = "Database subnet CIDR"
}

variable "subnet_az" {
  type        = string
  description = "Availability zone for app subnet"
}

variable "db_subnet_az" {
  type        = string
  description = "Availability zone for DB subnet"
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "subnet_id" {
  type    = string
  default = ""
}

variable "db_subnet_id" {
  type    = string
  default = ""
}

variable "cluster_version" {
  type    = string
  default = "1.29"
}

variable "cluster_endpoint_public" {
  type    = bool
  default = true
}

variable "apps_instance_type" {
  type    = string
  default = "t3.small"
}

variable "apps_min" {
  type    = number
  default = 1
}

variable "apps_desired" {
  type    = number
  default = 1
}

variable "apps_max" {
  type    = number
  default = 2
}

variable "apps_capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

variable "monitoring_instance_type" {
  type    = string
  default = "t3.small"
}

variable "monitoring_min" {
  type    = number
  default = 1
}

variable "monitoring_desired" {
  type    = number
  default = 1
}

variable "monitoring_max" {
  type    = number
  default = 2
}

variable "monitoring_capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

variable "gha_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "gha_min" {
  type    = number
  default = 0
}

variable "gha_desired" {
  type    = number
  default = 0
}

variable "gha_max" {
  type    = number
  default = 2
}

variable "gha_capacity_type" {
  type    = string
  default = "SPOT"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "github_actions_role_arn" {
  type        = string
  description = "IAM Role ARN for GitHub Actions access"
}

variable "students_access_key_ids" {
  type        = map(string)
  description = "Access key IDs of student IAM users"
}

variable "students_secret_access_keys" {
  type        = map(string)
  description = "Secret access keys of student IAM users"
  sensitive   = true
}

variable "students_usernames" {
  description = "List of IAM student usernames"
  type        = list(string)
}
