variable "project_id" {
  type        = string
  description = "ID du projet ou nom logique (ex: student-team1-dev)"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "cluster_name" {
  type        = string
  description = "Nom du cluster EKS"
  default     = "tmgr-eks"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC (ex: 10.0.0.0/16)"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR block for the subnet (ex: 10.0.1.0/24)"
}

variable "subnet_az" {
  type        = string
  description = "Availability Zone de la subnet (ex: eu-west-3b)"
  default     = "eu-west-3b"
}
