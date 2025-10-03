terraform {
  backend "s3" {
    bucket         = "terraform-permissions-state-bucket"
    key            = "iac/team1-dev/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
