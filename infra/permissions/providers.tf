terraform {
  backend "s3" {
    bucket         = "team-terraform-state-iac-projet-etu1-dev"
    key            = "permissions/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "terraform-locks"
  }
}
