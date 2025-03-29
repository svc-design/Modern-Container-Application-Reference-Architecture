import os
import pulumi
import pulumi_aws as aws
from utils.config_loader import load_merged_config
from modules.vpc.vpc import create_vpc
from modules.security_group.sg import create_security_group
from modules.ec2.ec2_instance import create_instances

# ✅ 自动从环境变量获取配置路径，默认为 "config/"
config_dir = os.environ.get("CONFIG_PATH", "config")
config = load_merged_config(config_dir)

# ✅ 提取配置项（如为空跳过）
aws_conf = config.get("aws")
vpc_conf = config.get("vpc")
instances_conf = config.get("instances", [])
firewall_rules = config.get("firewall_rules", [])

if not aws_conf or not vpc_conf:
    pulumi.log.warn(f"❌ 配置不完整，缺少 aws 或 vpc 段，终止部署。CONFIG_PATH={config_dir}")
    exit(0)

# ✅ 配置 AWS 凭据
aws.config.region = aws_conf["region"]
aws.config.access_key = aws_conf["access_key"]
aws.config.secret_key = aws_conf["secret_key"]

# ✅ 创建 VPC 与子网
vpc_result = create_vpc(vpc_conf, aws_conf["region"])
vpc = vpc_result["vpc"]
subnets = vpc_result["subnets"]

# ✅ 创建安全组（取第一组规则）
if not firewall_rules:
    pulumi.log.warn("⚠️ 未定义 firewall_rules，默认跳过安全组配置")
    sg_id = None
else:
    sg = create_security_group(vpc.id, firewall_rules[0])
    sg_id = sg.id

# ✅ SSH 密钥对
key_cfg = aws_conf["key_pairs"][0]
public_key_path = key_cfg["key_file"]
if not os.path.exists(public_key_path):
    raise FileNotFoundError(f"❌ SSH 公钥文件不存在: {public_key_path}")
with open(public_key_path, "r") as f:
    public_key = f.read().strip()

key_pair = aws.ec2.KeyPair("main-key",
    key_name=key_cfg["name"],
    public_key=public_key
)

# ✅ 创建实例（自动匹配子网）
if not instances_conf:
    pulumi.log.warn("⚠️ 未配置任何 EC2 实例，跳过实例部署")
    outputs = {}
else:
    outputs = create_instances(instances_conf, subnets, sg_id, key_pair.key_name)

# ✅ 导出所有实例的公网 IP
for name, ip in outputs.items():
    pulumi.export(f"{name}_ip", ip)
