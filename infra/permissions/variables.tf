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
  description = "AWS region (e.g., eu-west-2)"
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID (utilisé pour référencer des ressources IAM existantes)"
}

variable "students" {
  description = "Liste des étudiants (uniquement usernames)"
  type = list(object({
    username = string
  }))
}
