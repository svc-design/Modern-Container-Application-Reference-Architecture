resource "aws_instance" "devops" {
  ami                    = "${local.data.image_id}"
  instance_type          = "${local.data.ec2_type}"
  vpc_security_group_ids = "${local.data.sg_id}"
  subnet_id              = "${local.data.subnet_id}"
  key_name               = "${local.data.key_name}"

  tags = {
    Name = "devops"
  }
}


