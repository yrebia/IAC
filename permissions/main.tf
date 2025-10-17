##########################################
# Provider AWS
##########################################
provider "aws" {
  region = var.region
}

##########################################
# Utilisateurs IAM - Étudiants & Jeremie
##########################################

variable "students" {
  type    = list(string)
  default = ["student1", "student2", "student3", "student4"]
}

# --- Comptes IAM étudiants ---
resource "aws_iam_user" "students" {
  for_each = toset(var.students)
  name     = each.value
  tags = {
    Project = var.project_id
    Env     = var.env
  }
}

# Permissions PowerUser + ChangePassword
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

# --- Compte Jeremie (exemple ReadOnly + console) ---
resource "aws_iam_user" "jeremie" {
  name = "jeremie"
  tags = {
    Project = var.project_id
    Env     = var.env
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
        Effect = "Allow",
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
  }
}

# Policy attachée au rôle GitHub Actions (Terraform)
resource "aws_iam_role_policy" "terraform_policy" {
  name = "TerraformPolicy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        // Backend TF
        "s3:*",
        "dynamodb:*",

        // Réseau VPC
        "ec2:CreateVpc", "ec2:DeleteVpc", "ec2:DescribeVpcs", "ec2:DescribeVpcAttribute", "ec2:ModifyVpcAttribute",
        "ec2:DescribeSubnets", "ec2:CreateSubnet", "ec2:DeleteSubnet",
        "ec2:DescribeRouteTables", "ec2:CreateRouteTable", "ec2:DeleteRouteTable", "ec2:AssociateRouteTable", "ec2:DisassociateRouteTable",
        "ec2:CreateInternetGateway", "ec2:AttachInternetGateway", "ec2:DetachInternetGateway", "ec2:DeleteInternetGateway",

        // Security Groups
        "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup", "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress",
        "ec2:DescribeSecurityGroupRules",         // 👈 MANQUANTE

        // IAM (lecture)
        "iam:GetUser", "iam:ListAccessKeys", "iam:GetLoginProfile", "iam:ListAttachedUserPolicies",

        // EKS (lecture providers)
        "eks:DescribeCluster", "eks:ListClusters",

        // RDS
        "rds:CreateDBSubnetGroup", "rds:ModifyDBSubnetGroup", "rds:DeleteDBSubnetGroup", "rds:DescribeDBSubnetGroups",
        "rds:CreateDBInstance", "rds:ModifyDBInstance", "rds:DeleteDBInstance", "rds:DescribeDBInstances",
        "rds:AddTagsToResource", "rds:ListTagsForResource",

        // Secrets Manager (lecture secret RDS)
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecrets",             // 👍 recommandé
        "secretsmanager:ListSecretVersionIds",    // 👍 recommandé

        // (si secret chiffré par CMK custom)
        "kms:Decrypt"
      ],
      Resource = "*"
    }]
  })
}

##########################################
# Accès EKS - GitHub Actions
##########################################
resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = "tmgr-eks3"
  principal_arn = aws_iam_role.github_actions_role.arn
  type          = "STANDARD"

  tags = {
    Project = var.project_id
    Env     = var.env
  }
}

resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = "tmgr-eks3"
  principal_arn = aws_iam_role.github_actions_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope { type = "cluster" }
}

##########################################
# Accès EKS - Étudiants
##########################################
resource "aws_eks_access_entry" "students" {
  for_each      = aws_iam_user.students
  cluster_name  = "tmgr-eks3"
  principal_arn = each.value.arn
  type          = "STANDARD"

  tags = {
    Project = var.project_id
    Env     = var.env
  }
}

resource "aws_eks_access_policy_association" "students_cluster_admin" {
  for_each      = aws_iam_user.students
  cluster_name  = "tmgr-eks3"
  principal_arn = each.value.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope { type = "cluster" }
}