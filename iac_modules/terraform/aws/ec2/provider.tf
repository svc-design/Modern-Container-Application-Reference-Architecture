provider "aws" {
  region     = "ap-east-1"
}

terraform {
  backend "s3" {
    bucket     = "msp-db"
    key        = "ec2/ec2/test/terraform-state/terraform-state"
    region     = "ap-east-1"
    dynamodb_table = "terraform"
  }
  required_providers {
    local = {
      source = "hashicorp/local"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.14.0"
    }
  }
  required_version = ">= 0.14.9"
}