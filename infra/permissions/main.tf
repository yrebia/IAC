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
    Statement = [
      {
        Effect = "Allow",
        Action = [
          # --- Terraform Backend
          "s3:*",
          "dynamodb:*",

          # --- EC2 / Network / VPC / SG
          "ec2:*",

          # --- IAM : gestion complète pour Terraform (EKS / RDS / roles)
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PassRole",
          "iam:GetRole",
          "iam:ListRoles",
          "iam:ListAttachedRolePolicies",
          "iam:CreateInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:TagRole",

          # --- EKS (cluster et nodegroups)
          "eks:*",

          # --- RDS (bases de données)
          "rds:*",

          # --- Secrets Manager (lecture / écriture secrets DB)
          "secretsmanager:*",

          # --- KMS (si secrets chiffrés)
          "kms:Decrypt",
          "kms:DescribeKey",

          # --- CloudWatch (logs du cluster EKS)
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

##########################################
# MODULE : Permissions EKS (aws-auth)
##########################################
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = "arn:aws:iam::289050431371:role/tmgr-eks-cluster-20251020162323087700000003"
        username = "eks-cluster-role"
        groups   = ["system:masters"]
      },
      {
        rolearn  = "arn:aws:iam::289050431371:role/GitHubActionsRole"
        username = "github-actions"
        groups   = ["system:masters"]
      }
    ])

    mapUsers = yamlencode([
      {
        userarn  = "arn:aws:iam::289050431371:user/pauline"
        username = "pauline"
        groups   = ["system:masters"]
      },
      {
        userarn  = "arn:aws:iam::289050431371:user/valentin"
        username = "valentin"
        groups   = ["system:masters"]
      },
      {
        userarn  = "arn:aws:iam::289050431371:user/younes"
        username = "younes"
        groups   = ["system:masters"]
      },
      {
        userarn  = "arn:aws:iam::289050431371:user/sami"
        username = "sami"
        groups   = ["system:masters"]
      }
    ])
  }
}

##########################################
# 👇 NOUVEAU : Autorisation EKS pour Terraform CI/CD
##########################################
resource "aws_iam_role_policy" "gha_terraform_eks_access" {
  name = "TerraformEKSAccess"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}
