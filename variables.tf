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

variable "db_subnet_cidr" {
  type        = string
  description = "CIDR block for the DB subnet (ex: 10.0.2.0/24)"
}

variable "db_subnet_az" {
  type        = string
  description = "Availability Zone de la subnet (ex: eu-west-3c)"
  default     = "eu-west-3c"
}

# Database variables
variable "db_engine" {
  type        = string
  description = "Database engine"
  default     = "postgres"
}

variable "db_engine_version" {
  type        = string
  description = "Database engine version"
  default     = "15.4"
}

variable "db_instance_class" {
  type        = string
  description = "Database instance class"
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "Database allocated storage in GB"
  default     = 20
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "appdb"
}

variable "db_username" {
  type        = string
  description = "Database master username"
  default     = "admin"
}

variable "db_password" {
  type        = string
  description = "Database master password"
  sensitive   = true
  default     = "ChangeMe123!"
}
