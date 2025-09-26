terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {} # on injecte la config via -backend-config
}

provider "aws" {
  region = var.region
}
