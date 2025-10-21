##########################################
# Wrapper du module Permissions
##########################################
locals {
  include_permissions = var.enable_permissions
}

module "permissions_enabled" {
  source = "./permissions"

  project_id     = var.enable_permissions ? var.project_id : null
  env            = var.enable_permissions ? var.env : null
  region         = var.enable_permissions ? var.region : null
  aws_account_id = var.enable_permissions ? var.aws_account_id : null

  students = var.enable_permissions ? [
    { username = "student1" },
    { username = "student2" },
    { username = "student3" },
    { username = "student4" }
  ] : []
}

locals {
  github_actions_role_arn = var.enable_permissions ? module.permissions_enabled.github_actions_role_arn : null
}
