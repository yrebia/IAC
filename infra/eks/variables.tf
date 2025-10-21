##########################################
# Variables pour le module EKS (simplifiées)
##########################################

variable "project_id" {
  type        = string
  description = "Project identifier"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "env" {
  type        = string
  description = "Environment name (dev, prod, etc)"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID used by the cluster"
}

variable "subnet_id" {
  type        = string
  description = "Application subnet ID"
}

variable "db_subnet_id" {
  type        = string
  description = "Database subnet ID"
}

variable "github_actions_role_arn" {
  type        = string
  description = "IAM Role ARN for GitHub Actions access"
}

variable "students" {
  description = "Liste des étudiants pour accès EKS"
  type = list(object({
    username = string
  }))
}

variable "aws_account_id" {
  description = "AWS Account ID pour construire les ARN IAM"
  type        = string
}
