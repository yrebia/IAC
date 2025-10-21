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

variable "students" {
  description = "Liste des étudiants pour accès EKS"
  type = list(object({
    username = string
  }))
}

variable "aws_account_id" {
  description = "AWS Account ID pour les ARN IAM"
  type        = string
}

##########################################
# Variables pour le module Database (RDS)
##########################################

variable "db_engine" {
  type        = string
  description = "Type du moteur de base de données (ex: postgres)"
  default     = "postgres"
}

variable "db_engine_version" {
  type        = string
  description = "Version du moteur de base de données"
  default     = "16.2"
}

variable "db_instance_class" {
  type        = string
  description = "Classe d'instance RDS"
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "Taille allouée (Go)"
  default     = 20
}

variable "db_name" {
  type        = string
  description = "Nom de la base de données"
  default     = "task_manager"
}

variable "db_username" {
  type        = string
  description = "Nom d’utilisateur maître de la base de données"
  default     = "admin"
}
