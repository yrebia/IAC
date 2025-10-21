variable "project_id" {
  description = "Project identifier (e.g., student-team1-dev)"
  type        = string
}

variable "env" {
  description = "Environment (e.g., dev or prod)"
  type        = string
}

variable "region" {
  description = "AWS region for IAM resources"
  type        = string
}

variable "students" {
  description = "List of students with name and email"
  type = list(object({
    username = string
    email    = string
    fullname = string
  }))
}
