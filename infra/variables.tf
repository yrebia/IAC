##########################################
# Variables globales
##########################################

variable "project_id" {
  type        = string
  description = "ID projet logique (ex: team1-dev)"
}

variable "region" {
  type        = string
  description = "Région AWS (ex: eu-west-3)"
}

variable "cluster_name" {
  type        = string
  description = "Nom du cluster EKS"
  default     = "tmgr-eks3"
}

##########################################
# Réseau
##########################################
variable "vpc_name" {
  type        = string
  description = "Nom du VPC"
}

variable "cidr_block" {
  type        = string
  description = "CIDR du VPC (mémo)"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR subnet app"
}

variable "subnet_az" {
  type        = string
  description = "AZ subnet app"
  default     = "eu-west-3b"
}

variable "db_subnet_cidr" {
  type        = string
  description = "CIDR subnet DB"
}

variable "db_subnet_az" {
  type        = string
  description = "AZ subnet DB"
  default     = "eu-west-3c"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID (optionnel, prioritaire sur le lookup)"
  default     = ""
}

##########################################
# Base de données (RDS)
##########################################
variable "db_engine" {
  type        = string
  description = "Type de moteur de base de données"
  default     = "postgres"
}

variable "db_engine_version" {
  type        = string
  description = "Version du moteur de base de données"
  default     = "15.4"
}

variable "db_instance_class" {
  type        = string
  description = "Classe d’instance RDS"
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "Taille du stockage RDS en Go"
  default     = 20
}

variable "db_name" {
  type        = string
  description = "Nom de la base de données"
  default     = "appdb"
}

variable "db_username" {
  type        = string
  description = "Nom d’utilisateur principal de la base"
  default     = "admin"
}

variable "db_password" {
  type        = string
  description = "Mot de passe administrateur de la base"
  sensitive   = true
  default     = "ChangeMe123!"
}
