# --- Variables venant de tes tfvars ---
variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "cidr_block" {
  type = string
} # mémo/validation (et filtre)

variable "subnet_cidr" {
  type = string
}

variable "subnet_az" {
  type = string
}

variable "db_subnet_cidr" {
  type = string
}

variable "db_subnet_az" {
  type = string
}

# Overrides optionnels (si tu connais déjà les IDs exacts)
variable "vpc_id" {
  type    = string
  default = ""
}

variable "subnet_id" {
  type        = string
  description = "ID du subnet applicatif existant (optionnel)"
  default     = ""
}

# --- EKS ---
variable "cluster_version" {
  type    = string
  default = "1.29"
}

variable "cluster_endpoint_public" {
  type    = bool
  default = true
}

# --- Node groups (apps) ---
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
  default = "ON_DEMAND" # ou "SPOT"
}

# --- Node group monitoring ---
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

# --- Node group GitHub Actions (gha) ---
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

# --- Variables DB présentes dans tes tfvars (pas utilisées ici) ---
variable "db_engine" {
  type    = string
  default = null
}

variable "db_engine_version" {
  type    = string
  default = null
}

variable "db_instance_class" {
  type    = string
  default = null
}

variable "db_allocated_storage" {
  type    = number
  default = null
}

variable "db_name" {
  type    = string
  default = null
}

variable "db_username" {
  type    = string
  default = null
}

variable "db_subnet_id" {
  type        = string
  description = "ID du subnet base de données existant (optionnel)"
  default     = ""
}
