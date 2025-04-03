import os
import sys
import pulumi
import pulumi_aws as aws
import boto3
from botocore.exceptions import ProfileNotFound, NoCredentialsError

from utils.config_loader import load_merged_config
from modules.vpc.vpc import create_vpcs
from modules.security_group.sg import create_security_group
from modules.ec2.ec2_instance import create_instances

# ✅ 加载配置
config_dir = os.environ.get("CONFIG_PATH", "config")
config = load_merged_config(config_dir)

aws_conf = config.get("aws", {})
region = aws_conf.get("region", "us-east-1")
profile = aws_conf.get("profile", "default")
key_pairs = aws_conf.get("key_pairs", [])

# ✅ 设置 AWS 配置
aws.config.region = region
aws.config.profile = profile
pulumi.runtime.set_config("aws:region", region)

# ✅ 检查 AWS 凭证
try:
    session = boto3.Session(profile_name=profile)
    credentials = session.get_credentials()
    if not credentials:
        raise NoCredentialsError()
except (ProfileNotFound, NoCredentialsError):
    pulumi.log.error(f"❌ AWS profile '{profile}' 无效或找不到凭证")
    sys.exit(1)
else:
    pulumi.log.info(f"✅ AWS credentials loaded (profile: {profile}, region: {region})")

# ✅ 初始化资源容器
global_dependencies = []
vpc = None
subnets = {}
sg = None
key_pair = None

# ========================
# ✅ [模块] VPC + Subnets
vpc_confs = config.get("vpcs", [])
if vpc_confs:
    vpc_results = create_vpcs(vpc_confs, region)
    all_subnets = {}
    for vpc_name, result in vpc_results.items():
        pulumi.log.info(f"✅ VPC {vpc_name} 已创建")
        global_dependencies.append(result["vpc"])
        global_dependencies.extend(result["subnets"].values())
        all_subnets.update(result["subnets"])
    subnets = all_subnets
else:
    pulumi.log.warn("⏭️ 跳过 VPC 创建")

# ========================
# ✅ [模块] Security Group
# ========================
firewall_rules = config.get("firewall_rules", [])
if firewall_rules and vpc and config.get("security_group", {}).get("enabled", True):
    sg = create_security_group(vpc.id, firewall_rules[0])
    global_dependencies.append(sg)
    pulumi.log.info("✅ Security Group 已创建")
else:
    pulumi.log.warn("⏭️ 跳过 Security Group 创建")

# ========================
# ✅ [模块] SSH Key Pair
# ========================
if key_pairs:
    key_cfg = key_pairs[0]
    public_key_path = os.path.expanduser(key_cfg["key_file"])
    if not os.path.exists(public_key_path):
        raise FileNotFoundError(f"❌ SSH 公钥文件不存在: {public_key_path}")
    with open(public_key_path) as f:
        public_key = f.read().strip()
    key_pair = aws.ec2.KeyPair("main-key",
        key_name=key_cfg["name"],
        public_key=public_key
    )
    global_dependencies.append(key_pair)
    pulumi.log.info("✅ SSH KeyPair 已创建")
else:
    pulumi.log.warn("⏭️ 跳过 KeyPair 创建")

# ========================
# ✅ [模块] EC2 实例部署
# ========================
instances_conf = config.get("instances", [])
ec2_outputs = {}

if instances_conf and config.get("ec2", {}).get("enabled", True):
    ec2_outputs = create_instances(
        instances_conf,
        subnets,
        sg,  # ✅ 注意这里传的是资源对象
        key_pair.key_name if key_pair else None,
        depends_on=global_dependencies
    )
    pulumi.log.info("✅ EC2 实例已创建")
else:
    pulumi.log.warn("⏭️ 跳过 EC2 实例部署")

# ========================
# ✅ 导出所有实例信息
# ========================
for name, ip in ec2_outputs.items():
    pulumi.export(f"{name}", ip)
