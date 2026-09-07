#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
main="${root}/main.tf"

terraform -chdir="${root}" fmt -check
[[ $(grep -Fc 'resource "aws_instance"' "${main}") -eq 2 ]]
[[ $(grep -Fc 'resource "aws_security_group"' "${main}") -eq 2 ]]

for forbidden in aws_vpc aws_subnet aws_internet_gateway aws_route_table aws_route_table_association aws_key_pair; do
  if grep -Fq "resource \"${forbidden}\"" "${main}"; then
    echo "UAT lab must reuse existing networking; forbidden resource: ${forbidden}" >&2
    exit 1
  fi
done

grep -Fq 'data "aws_vpc" "uat"' "${main}"
grep -Fq 'data "aws_subnets" "uat"' "${main}"
grep -Fq 'var.aws_client_instance_type == "t4g.micro"' "${main}"
grep -Fq 'var.aws_gateway_instance_type == "t4g.small"' "${main}"
[[ $(grep -Fc 'market_type = "spot"' "${main}") -eq 2 ]]
[[ $(grep -Fc 'spot_instance_type             = "one-time"' "${main}") -eq 2 ]]
[[ $(grep -Fc 'instance_interruption_behavior = "terminate"' "${main}") -eq 2 ]]
grep -Fq 'Environment = "uat"' "${main}"
grep -Fq "'\${ssh_public_key}'" "${root}/bootstrap.sh"

echo 'XConnect UAT IaC contract creates two ARM64 Spot nodes and reuses the UAT network.'
