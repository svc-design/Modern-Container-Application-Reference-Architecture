resource "aws_instance" "this" {
  ami                                  = var.instance.ami
  instance_type                        = var.instance.type
  instance_initiated_shutdown_behavior = var.max_runtime_minutes > 0 ? "terminate" : "stop"

  dynamic "instance_market_options" {
    for_each = var.spot_instance ? [true] : []
    content {
      market_type = "spot"

      spot_options {
        spot_instance_type             = "one-time"
        instance_interruption_behavior = "terminate"
      }
    }
  }

  # UAT Spot nodes are intentionally ephemeral. The shutdown is initiated on
  # the instance so AWS applies the terminate behavior above without requiring
  # a long-running CI job or separately privileged scheduler.
  user_data = var.max_runtime_minutes > 0 ? format(
    "#!/bin/sh\nset -eu\n(\n  sleep %d\n  /sbin/shutdown -h now\n) >/var/log/instance-runtime-limit.log 2>&1 &\n",
    var.max_runtime_minutes * 60,
  ) : null

  # 明确由 env 层传入，无任何自动推断
  subnet_id = var.subnet_id

  vpc_security_group_ids = [var.sg_id]

  key_name = var.keypair_name

  # The instance may be stopped, but termination must be explicitly unblocked.
  disable_api_termination = var.deletion_protection
  disable_api_stop        = false

  lifecycle {
    # Terraform requires prevent_destroy to be a literal, not a variable.
    # All instances created by this shared module are therefore protected.
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-instance"
  })
}

resource "aws_eip" "this" {
  count  = var.elastic_ip ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eip"
  })
}

resource "aws_eip_association" "this" {
  count         = var.elastic_ip ? 1 : 0
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this[0].id
}
