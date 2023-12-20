resource "aws_key_pair" "devops" {
  key_name   = "${local.data.devops.name}"
  public_key = "${local.data.devops.pubkey}"
}
