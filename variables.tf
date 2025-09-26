variable "project_id" {
  type        = string
  description = "ID du projet ou nom logique (ex: student-team1-dev)"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}
