resource "aws_vpc" "devops" {
  cidr_block           = "${local.data.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "subnet_web" {
  # creates a subnet
  cidr_block        = "${cidrsubnet(aws_vpc.devops.cidr_block, 8, 0)}"
  vpc_id            = "${aws_vpc.devops.id}"
  availability_zone = "${local.data.az}"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_db" {
  # creates a subnet
  cidr_block        = "${cidrsubnet(aws_vpc.devops.cidr_block, 8, 1)}"
  vpc_id            = "${aws_vpc.devops.id}"
  availability_zone = "${local.data.az}"
}

resource "aws_internet_gateway" "devops" {
  vpc_id = "${aws_vpc.devops.id}"
}

resource "aws_route_table" "devops" {
  vpc_id = "${aws_vpc.devops.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.devops.id}"
  }
}

resource "aws_route_table_association" "subnet-association-devops" {
  subnet_id      = "${aws_subnet.subnet_web.id}"
  route_table_id = "${aws_route_table.devops.id}"
}

