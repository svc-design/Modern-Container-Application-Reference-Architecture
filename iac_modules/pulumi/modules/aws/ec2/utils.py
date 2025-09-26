import pulumi_aws as aws

AMI_MAP = {
    "ubuntu-22.04": ("099720109477", "*ubuntu*22.04*"),
    "ubuntu-24.04": ("099720109477", "*ubuntu*24.04*"),
    "rocky-8.10": ("792107900819", "Rocky-8-ec2-8.10*"),
    "amazonlinux-2": ("137112412989", "amzn2-ami-hvm-*-gp2"),
    "amazonlinux-2023": ("137112412989", "al2023-ami-*-x86_64"),
    "debian-12": ("136693071363", "debian-12-*"),
    "almalinux-9": ("151447241410", "AlmaLinux-9-*"),
}

def query_latest_ami(owner: str, name_filter: str, architecture: str = "x86_64") -> str:
    result = aws.ec2.get_ami(
        most_recent=True,
        owners=[owner],
        filters=[
            {"name": "name", "values": [name_filter]},
            {"name": "architecture", "values": [architecture]},
            {"name": "virtualization-type", "values": ["hvm"]},
        ],
    )
    return result.id

def resolve_ami(ami_keyword: str, region: str, architecture: str = "x86_64") -> str:
    if not aws.config.region:
        raise ValueError("❌ AWS region is not set. Please set aws.config.region before calling resolve_ami")

    if ami_keyword.startswith("ami-"):
        return ami_keyword

    keyword = ami_keyword.lower()
    print(f"🔍 Resolving AMI for keyword='{keyword}' in region='{region}' with arch='{architecture}'")

    if keyword in AMI_MAP:
        owner, name_filter = AMI_MAP[keyword]
        try:
            return query_latest_ami(owner, name_filter, architecture)
        except Exception as e:
            raise ValueError(f"❌ Failed to find AMI for '{keyword}' in region '{region}': {e}")

    raise ValueError(f"❌ Unsupported AMI keyword: {ami_keyword}. Supported keywords: {list(AMI_MAP.keys())}")

