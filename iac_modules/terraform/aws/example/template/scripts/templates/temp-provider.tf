provider "aws" {
  region  = "cn-northwest-1"  
}

terraform {
  backend "s3" {
    bucket     = "{{ vars.iac_state.s3 }}"
    key        = "{{ vars.iac_state.key }}"
    region     = "{{ vars.count.region }}"
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
