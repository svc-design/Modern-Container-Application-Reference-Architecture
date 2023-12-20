provider "aws" {
  region     = "{{ vars.count.region }}"
}

terraform {
  backend "s3" {
    bucket     = "{{ vars.iac_state.s3 }}"
    key        = "ec2/{{ vars.iac_state.key }}/terraform-state"
    region     = "{{ vars.count.region }}"
    dynamodb_table = "terraform"
  }
  required_providers {
    local = {
      source = "hashicorp/local"
    }
    aws = {
      source  = "hashicorp/aws"
    }
  }
}
