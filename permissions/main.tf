provider "aws" {
  region = var.region
}

variable "students" {
  type    = list(string)
  default = ["student1", "student2", "student3", "student4"]
}

resource "aws_iam_user" "students" {
  for_each = toset(var.students)
  name     = each.value
  tags = {
    Project = var.project_id
    Env     = var.env
  }
}

resource "aws_iam_user_policy_attachment" "students_power" {
  for_each   = aws_iam_user.students
  user       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

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

resource "aws_iam_access_key" "jeremie" {
  user = aws_iam_user.jeremie.name
}

resource "aws_iam_user_login_profile" "jeremie_console" {
  user                    = aws_iam_user.jeremie.name
  password_length         = 20
  password_reset_required = true
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

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
  }
}

resource "aws_iam_role_policy" "terraform_policy" {
  name = "TerraformPolicy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "dynamodb:*",
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcAttribute",
          "ec2:ModifyVpcAttribute",
          "ec2:DescribeSubnets",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:DescribeRouteTables",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:DeleteInternetGateway",
          "iam:GetUser",
          "iam:ListAccessKeys",
          "iam:GetLoginProfile",
          "iam:ListAttachedUserPolicies"
        ]
        Resource = "*"
      }
    ]
  })
}
