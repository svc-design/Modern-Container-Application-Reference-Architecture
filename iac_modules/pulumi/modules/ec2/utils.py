import pulumi_aws as aws

def resolve_ami(ami_keyword: str, region: str) -> str:
    """
    根据关键词解析 AMI ID。如果已是 AMI ID，则直接返回。
    """
    if not aws.config.region:
        raise ValueError("❌ AWS region is not set. Please set aws.config.region before calling resolve_ami")

    if ami_keyword.startswith("ami-"):
        return ami_keyword

    keyword = ami_keyword.lower()

    if keyword in ["ubuntu-22.04", "ubuntu22.04"]:
        result = aws.ec2.get_ami(
            most_recent=True,
            owners=["099720109477"],  # Canonical
            filters=[
                {"name": "name", "values": ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]},
                {"name": "virtualization-type", "values": ["hvm"]},
            ],
        )
        return result.id

    if keyword in ["rocky-8.10", "rockylinux-8.10", "rocky8.10"]:
        result = aws.ec2.get_ami(
            most_recent=True,
            owners=["792107900819"],  # Rocky Linux
            filters=[
                {"name": "name", "values": ["Rocky-8-ec2-8.10*x86_64"]},
                {"name": "architecture", "values": ["x86_64"]},
            ],
        )
        return result.id

    raise ValueError(f"❌ Unsupported AMI keyword: {ami_keyword}")
