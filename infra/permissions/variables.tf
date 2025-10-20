variable "project_id" {
  type        = string
  description = "Project identifier (eg: student-team1-dev)"
}

variable "env" {
  type        = string
  description = "Environment (dev or prd)"
}

variable "region" {
  type        = string
  description = "AWS region for IAM resources"
}

variable "cluster_name" {
  description = "Nom du cluster EKS"
  type        = string
}
