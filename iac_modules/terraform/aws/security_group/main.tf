resource "aws_security_group" "allow_https" {
  name   = "allow_https"
  vpc_id = "${local.data.vpc_id}"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]

    from_port = 0
    to_port   = 0
    protocol  = "-1"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]

    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]

    from_port = 443
    to_port   = 443
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
