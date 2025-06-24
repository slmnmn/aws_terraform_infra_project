provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket = "tfstateformyprojectgg"
    key    = "state.tf"
    region = "us-east-1"
  }
}
