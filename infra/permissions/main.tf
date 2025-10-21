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
# Provider AWS
##########################################
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = var.project_id
      Env       = var.env
      Purpose   = "IAM Management"
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

  tags = {
    Project  = var.project_id
    Env      = var.env
    Email    = each.value.email
    FullName = each.value.fullname
    Role     = "Student"
  }
}

# --- Policies pour les étudiants ---
resource "aws_iam_user_policy_attachment" "students_power" {
  for_each   = aws_iam_user.students
  user       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_user_policy_attachment" "students_change_password" {
  for_each   = aws_iam_user.students
  user       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

# --- Clés d’accès pour les étudiants ---
resource "aws_iam_access_key" "students" {
  for_each = aws_iam_user.students
  user     = each.value.name
}

# --- Comptes IAM Jérémie (ReadOnly + console) ---
resource "aws_iam_user" "jeremie" {
  name = "jeremie"
  tags = {
    Project = var.project_id
    Env     = var.env
    Role    = "Instructor"
  }
}

resource "aws_iam_user_policy_attachment" "jeremie_readonly" {
  user       = aws_iam_user.jeremie.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_user_policy_attachment" "jeremie_change_password" {
  user       = aws_iam_user.jeremie.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_access_key" "jeremie" {
  user = aws_iam_user.jeremie.name
}

resource "aws_iam_user_login_profile" "jeremie_console" {
  user                    = aws_iam_user.jeremie.name
  password_length         = 20
  password_reset_required = true
}

##########################################
# OpenID Connect Provider pour GitHub Actions
##########################################
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
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
        Effect = "Allow",
        Action = [
          # Terraform Backend
          "s3:*",
          "dynamodb:*",

          # EC2 / Network / VPC / SG
          "ec2:*",

          # IAM Management
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:UpdateAssumeRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:ListRoles",
          "iam:ListAttachedRolePolicies",

          # EKS / RDS / Secrets
          "eks:*",
          "rds:*",
          "secretsmanager:*",

          # KMS / Logs
          "kms:Decrypt",
          "kms:DescribeKey",
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy"
        ],
        Resource = "*"
      }
    ]
  })
}

##########################################
# Fichiers de credentials locaux
##########################################
resource "local_file" "students_credentials" {
  for_each = aws_iam_access_key.students
  filename = "${path.module}/credentials/${each.key}_credentials.json"
  content = jsonencode({
    username          = each.key
    access_key_id     = each.value.id
    secret_access_key = each.value.secret
    region            = var.region
  })
  file_permission = "0600"
}

resource "local_file" "jeremie_credentials" {
  filename = "${path.module}/credentials/jeremie_credentials.json"
  content = jsonencode({
    username          = aws_iam_user.jeremie.name
    access_key_id     = aws_iam_access_key.jeremie.id
    secret_access_key = aws_iam_access_key.jeremie.secret
    region            = var.region
  })
  file_permission = "0600"
}
