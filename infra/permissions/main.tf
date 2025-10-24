##########################################
# Terraform
##########################################
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

##########################################
# Utilisateurs IAM - Étudiants & Jérémie
##########################################

# --- Comptes IAM étudiants ---
resource "aws_iam_user" "students" {
  for_each = { for s in var.students : s.username => s }

  name = each.value.username

  # Ignore les changements externes (ex : console AWS)
  lifecycle {
    ignore_changes = all
  }

  tags = {
    Project = var.project_id
    Env     = var.env
    Role    = "Student"
  }
}

# --- Clés d’accès pour les étudiants ---
resource "aws_iam_access_key" "students" {
  for_each = aws_iam_user.students
  user     = each.value.name

  # ✅ Supprimer la clé avant de supprimer l'utilisateur
  lifecycle {
    prevent_destroy = false
  }

  depends_on = [
    aws_iam_user.students
  ]
}

# --- Policies pour les étudiants ---
resource "aws_iam_user_policy_attachment" "students_power" {
  for_each   = aws_iam_user.students
  user       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"

  depends_on = [
    aws_iam_user.students
  ]
}

resource "aws_iam_user_policy_attachment" "students_change_password" {
  for_each   = aws_iam_user.students
  user       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"

  depends_on = [
    aws_iam_user.students
  ]
}

# Custom policy to allow IAM read operations for Terraform
resource "aws_iam_policy" "students_iam_read" {
  name        = "StudentsIAMReadAccess"
  description = "Allow students to read IAM resources for Terraform state refresh"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "students_iam_read" {
  for_each   = aws_iam_user.students
  user       = each.value.name
  policy_arn = aws_iam_policy.students_iam_read.arn

  depends_on = [
    aws_iam_user.students
  ]
}

# --- Assurer l’ordre de suppression ---
# Terraform détruit les access_keys et policies AVANT les utilisateurs.
# (grâce au depends_on implicite)
resource "null_resource" "students_cleanup" {
  for_each = aws_iam_user.students

  depends_on = [
    aws_iam_access_key.students,
    aws_iam_user_policy_attachment.students_power,
    aws_iam_user_policy_attachment.students_change_password
  ]
}

##########################################
# Compte IAM Jérémie (existant)
##########################################
data "aws_iam_user" "jeremie" {
  user_name = "jeremie"
}

resource "aws_iam_user_policy_attachment" "jeremie_readonly" {
  user       = data.aws_iam_user.jeremie.user_name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_user_policy_attachment" "jeremie_change_password" {
  user       = data.aws_iam_user.jeremie.user_name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_access_key" "jeremie" {
  user = data.aws_iam_user.jeremie.user_name
}

resource "aws_iam_user_login_profile" "jeremie_console" {
  user = data.aws_iam_user.jeremie.user_name

  lifecycle {
    ignore_changes = [
      password,
      password_reset_required,
      password_length,
    ]
  }
}

##########################################
# OpenID Connect Provider GitHub (existant)
##########################################
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  lifecycle {
    ignore_changes = all
  }
}

##########################################
# Rôle GitHub Actions + Policy Terraform
##########################################
resource "aws_iam_role" "github_actions_role" {
  name = "GitHubActionsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:yrebia/IAC:*"
          }
        }
      }
    ]
  })

  tags = {
    Project = var.project_id
    Env     = var.env
    Role    = "GitHubActions"
  }
}

resource "aws_iam_role_policy" "terraform_policy" {
  name = "TerraformPolicy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "TerraformCoreAccess"
        Effect = "Allow"
        Action = [
          "s3:*",
          "dynamodb:*",
          "ec2:*",
          "iam:*",
          "eks:*",
          "rds:*",
          "secretsmanager:*",
          "kms:*",
          "logs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

##########################################
# Fichiers credentials locaux
##########################################
resource "local_file" "students_credentials" {
  for_each = { for s in var.students : s.username => s }

  filename = "${path.module}/credentials/${each.key}_credentials.json"

  content = jsonencode({
    username          = each.key
    access_key_id     = aws_iam_access_key.students[each.key].id
    secret_access_key = aws_iam_access_key.students[each.key].secret
    region            = var.region
  })

  file_permission = "0600"
}

resource "local_file" "jeremie_credentials" {
  filename = "${path.module}/credentials/jeremie_credentials.json"
  content = jsonencode({
    username          = data.aws_iam_user.jeremie.user_name
    access_key_id     = aws_iam_access_key.jeremie.id
    secret_access_key = aws_iam_access_key.jeremie.secret
    region            = var.region
  })
  file_permission = "0600"
}

##########################################
# Outputs
##########################################
output "students_access_keys" {
  value = {
    for user, key in aws_iam_access_key.students :
    user => {
      access_key_id     = key.id
      secret_access_key = key.secret
    }
  }
  sensitive = true
}
