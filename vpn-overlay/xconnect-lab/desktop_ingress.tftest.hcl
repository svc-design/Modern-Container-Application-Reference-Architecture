mock_provider "aws" {
  override_data {
    target = data.aws_vpc.uat
    values = {
      id = "vpc-0123456789abcdef0"
    }
  }

  override_data {
    target = data.aws_subnets.uat
    values = {
      ids = ["subnet-0123456789abcdef0"]
    }
  }
}

variables {
  run_id                    = "xcl-123-1"
  expires_at                = "2026-09-08T12:00:00Z"
  runner_cidr               = "198.51.100.10/32"
  ssh_public_key            = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample desktop-test"
  aws_region                = "us-east-1"
  aws_client_instance_type  = "t4g.micro"
  aws_gateway_instance_type = "t4g.small"
  aws_ami                   = "ami-0123456789abcdef0"
  zero_accounts_api_url     = "https://accounts.example.test"
  zero_portal_url           = "https://portal.example.test"
}

run "empty_list_is_valid" {
  command = plan
  variables {
    desktop_ingress_cidrs = []
  }
}

run "one_canonical_ipv4_32_is_valid" {
  command = plan
  variables {
    desktop_ingress_cidrs = ["198.51.100.42/32"]
  }
}

run "two_canonical_ipv4_32s_are_valid" {
  command = plan
  variables {
    desktop_ingress_cidrs = ["198.51.100.42/32", "203.0.113.7/32"]
  }
}

run "zero_network_is_invalid" {
  command = plan
  variables {
    desktop_ingress_cidrs = ["0.0.0.0/0"]
  }
  expect_failures = [var.desktop_ingress_cidrs]
}

run "non_host_network_is_invalid" {
  command = plan
  variables {
    desktop_ingress_cidrs = ["198.51.100.0/24"]
  }
  expect_failures = [var.desktop_ingress_cidrs]
}

run "ipv6_is_invalid" {
  command = plan
  variables {
    desktop_ingress_cidrs = ["2001:db8::1/32"]
  }
  expect_failures = [var.desktop_ingress_cidrs]
}

run "leading_space_is_invalid" {
  command = plan
  variables {
    desktop_ingress_cidrs = [" 198.51.100.42/32"]
  }
  expect_failures = [var.desktop_ingress_cidrs]
}

run "trailing_space_is_invalid" {
  command = plan
  variables {
    desktop_ingress_cidrs = ["198.51.100.42/32 "]
  }
  expect_failures = [var.desktop_ingress_cidrs]
}

run "duplicate_is_invalid" {
  command = plan
  variables {
    desktop_ingress_cidrs = ["198.51.100.42/32", "198.51.100.42/32"]
  }
  expect_failures = [var.desktop_ingress_cidrs]
}

run "three_items_are_invalid" {
  command = plan
  variables {
    desktop_ingress_cidrs = ["198.51.100.42/32", "203.0.113.7/32", "192.0.2.9/32"]
  }
  expect_failures = [var.desktop_ingress_cidrs]
}

run "invalid_string_is_invalid" {
  command = plan
  variables {
    desktop_ingress_cidrs = ["not-a-cidr"]
  }
  expect_failures = [var.desktop_ingress_cidrs]
}

run "null_is_invalid" {
  command = plan
  variables {
    desktop_ingress_cidrs = null
  }
  expect_failures = [var.desktop_ingress_cidrs]
}
