terraform {
  required_version = ">= 1.9.5, < 2.0.0"
  required_providers {
    aws   = { source = "hashicorp/aws", version = "~> 5.0" }
    vultr = { source = "vultr/vultr", version = "~> 2.0" }
  }
  backend "s3" {}
}

variable "run_id" {
  type = string
  validation {
    condition     = can(regex("^xcl-[0-9]+-[0-9]+$", var.run_id))
    error_message = "Use xcl-GITHUB_RUN_ID-GITHUB_RUN_ATTEMPT, never an environment name."
  }
}

variable "expires_at" { type = string }

variable "runner_cidr" {
  type = string
  validation {
    condition     = can(cidrnetmask(var.runner_cidr)) && endswith(var.runner_cidr, "/32")
    error_message = "Runner access must be one IPv4 /32."
  }
}

variable "ssh_public_key" { type = string }
variable "aws_region" { type = string }
variable "aws_instance_type" { type = string }
variable "aws_ami" { type = string }
variable "vpc_cidr" { type = string }

variable "gateway_provider" {
  type    = string
  default = "aws-spot"
  validation {
    condition     = contains(["aws-spot", "vultr"], var.gateway_provider)
    error_message = "gateway_provider must be aws-spot or the explicitly selected optional vultr backend."
  }
}

variable "vultr_region" {
  type    = string
  default = ""
}

variable "vultr_plan" {
  type    = string
  default = ""
}

variable "vultr_os_id" {
  type    = number
  default = 0
}

variable "zero_accounts_api_url" {
  type = string
  validation {
    condition     = can(regex("^https://", var.zero_accounts_api_url))
    error_message = "zero_accounts_api_url must be an HTTPS XConnect Zero accounts API URL."
  }
}

variable "zero_portal_url" {
  type = string
  validation {
    condition     = can(regex("^https://", var.zero_portal_url))
    error_message = "zero_portal_url must be an HTTPS XConnect Zero portal URL."
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = { ManagedBy = "xconnect-lab", LabRun = var.run_id, ExpiresAt = var.expires_at, Environment = "sit" }
  }
}

# This provider is intentionally inert for the default aws-spot path. The
# workflow only loads VULTR_API_KEY when gateway_provider=vultr.
provider "vultr" {}

resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "lab" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.vpc_cidr
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "lab" { vpc_id = aws_vpc.lab.id }

resource "aws_route_table" "lab" {
  vpc_id = aws_vpc.lab.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }
}

resource "aws_route_table_association" "lab" {
  subnet_id      = aws_subnet.lab.id
  route_table_id = aws_route_table.lab.id
}

resource "aws_security_group" "client" {
  name   = "${var.run_id}-client"
  vpc_id = aws_vpc.lab.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.runner_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "gateway" {
  name   = "${var.run_id}-gateway"
  vpc_id = aws_vpc.lab.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.runner_cidr]
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.client.id]
    description     = "Xray TLS from the controlled client only"
  }
  ingress {
    from_port       = 8443
    to_port         = 8443
    protocol        = "tcp"
    security_groups = [aws_security_group.client.id]
    description     = "Experimental lab-controller API from the controlled client"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "lab" {
  key_name   = var.run_id
  public_key = var.ssh_public_key
}

resource "aws_instance" "gateway" {
  count                       = var.gateway_provider == "aws-spot" ? 1 : 0
  ami                         = var.aws_ami
  instance_type               = var.aws_instance_type
  subnet_id                   = aws_subnet.lab.id
  vpc_security_group_ids      = [aws_security_group.gateway.id]
  key_name                    = aws_key_pair.lab.key_name
  associate_public_ip_address = true
  user_data = templatefile("${path.module}/bootstrap.sh", {
    role   = "relay"
    run_id = var.run_id
  })
  instance_market_options {
    market_type = "spot"
    spot_options {
      spot_instance_type             = "one-time"
      instance_interruption_behavior = "terminate"
    }
  }
  metadata_options { http_tokens = "required" }
  root_block_device {
    volume_size           = 12
    encrypted             = true
    delete_on_termination = true
  }
  tags       = { Name = "${var.run_id}-gateway", XConnectRole = "relay" }
  depends_on = [aws_route_table_association.lab]
}

resource "aws_instance" "client" {
  ami                         = var.aws_ami
  instance_type               = var.aws_instance_type
  subnet_id                   = aws_subnet.lab.id
  vpc_security_group_ids      = [aws_security_group.client.id]
  key_name                    = aws_key_pair.lab.key_name
  associate_public_ip_address = true
  user_data = templatefile("${path.module}/bootstrap.sh", {
    role   = "controlled-client"
    run_id = var.run_id
  })
  instance_market_options {
    market_type = "spot"
    spot_options {
      spot_instance_type             = "one-time"
      instance_interruption_behavior = "terminate"
    }
  }
  metadata_options { http_tokens = "required" }
  root_block_device {
    volume_size           = 12
    encrypted             = true
    delete_on_termination = true
  }
  tags       = { Name = "${var.run_id}-client", XConnectRole = "controlled-client" }
  depends_on = [aws_route_table_association.lab]
}

resource "vultr_ssh_key" "lab" {
  count   = var.gateway_provider == "vultr" ? 1 : 0
  name    = var.run_id
  ssh_key = var.ssh_public_key
}

resource "vultr_firewall_group" "lab" {
  count       = var.gateway_provider == "vultr" ? 1 : 0
  description = var.run_id
}

resource "vultr_firewall_rule" "ssh" {
  count             = var.gateway_provider == "vultr" ? 1 : 0
  firewall_group_id = vultr_firewall_group.lab[0].id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = split("/", var.runner_cidr)[0]
  subnet_size       = 32
  port              = "22"
}

resource "vultr_firewall_rule" "client" {
  count             = var.gateway_provider == "vultr" ? 1 : 0
  firewall_group_id = vultr_firewall_group.lab[0].id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = aws_instance.client.public_ip
  subnet_size       = 32
  port              = "443"
}

resource "vultr_firewall_rule" "zero" {
  count             = var.gateway_provider == "vultr" ? 1 : 0
  firewall_group_id = vultr_firewall_group.lab[0].id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = aws_instance.client.public_ip
  subnet_size       = 32
  port              = "8443"
}

resource "vultr_instance" "gateway" {
  count             = var.gateway_provider == "vultr" ? 1 : 0
  region            = var.vultr_region
  plan              = var.vultr_plan
  os_id             = var.vultr_os_id
  label             = "${var.run_id}-gateway"
  hostname          = "${var.run_id}-gateway"
  tags              = ["xconnect-lab", var.run_id, "expires-${replace(var.expires_at, ":", "-")}"]
  ssh_key_ids       = [vultr_ssh_key.lab[0].id]
  firewall_group_id = vultr_firewall_group.lab[0].id
  enable_ipv6       = false
  backups           = "disabled"
  activation_email  = false
  depends_on        = [vultr_firewall_rule.ssh, vultr_firewall_rule.client, vultr_firewall_rule.zero]
}

output "gateway_provider" { value = var.gateway_provider }
output "gateway_role" { value = "relay" }
output "client_role" { value = "controlled-client" }
output "client_ip" { value = aws_instance.client.public_ip }
output "client_private_ip" { value = aws_instance.client.private_ip }

output "gateway_ip" {
  value = var.gateway_provider == "aws-spot" ? aws_instance.gateway[0].public_ip : vultr_instance.gateway[0].main_ip
}

output "gateway_private_ip" {
  value = var.gateway_provider == "aws-spot" ? aws_instance.gateway[0].private_ip : ""
}

output "gateway_transport_ip" {
  value = var.gateway_provider == "aws-spot" ? aws_instance.gateway[0].private_ip : vultr_instance.gateway[0].main_ip
}

output "gateway_ssh_user" {
  value = var.gateway_provider == "aws-spot" ? "ubuntu" : "root"
}

output "client_ssh_user" { value = "ubuntu" }
output "zero_accounts_api_url" { value = var.zero_accounts_api_url }
output "zero_portal_url" { value = var.zero_portal_url }

output "lab_controller_url" {
  value = "https://${var.gateway_provider == "aws-spot" ? aws_instance.gateway[0].public_ip : vultr_instance.gateway[0].main_ip}:8443"
}

output "resource_ids" {
  value = {
    client         = aws_instance.client.id
    gateway        = var.gateway_provider == "aws-spot" ? aws_instance.gateway[0].id : vultr_instance.gateway[0].id
    gateway_role   = "relay"
    client_role    = "controlled-client"
    gateway_source = var.gateway_provider
    run            = var.run_id
  }
}
