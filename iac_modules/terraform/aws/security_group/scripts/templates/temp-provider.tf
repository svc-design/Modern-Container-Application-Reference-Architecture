provider "aws" {
  region     = "{{ vars.count.region }}"
}

terraform {
  backend "s3" {
    bucket     = "{{ vars.iac_state.s3 }}"
    key        = "sg/{{ vars.iac_state.key }}/terraform-state"
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
