import os
import pulumi
import pulumi_aws as aws
from .utils import resolve_ami

def create_instances(instances_config, subnets_dict, sg_map: dict, key_name, depends_on=None):
    outputs = {}

    for instance_cfg in instances_config:
        name = instance_cfg["name"]
        subnet_name = instance_cfg["subnet"]
        subnet = subnets_dict[subnet_name]
        subnet_id = subnet.id

        region = aws.config.region
        ami = resolve_ami(instance_cfg["ami"], region)
        instance_type = instance_cfg["type"]
        disk_size = instance_cfg["disk_size_gb"]

        lifecycle = instance_cfg.get("lifecycle", "ondemand")
        ttl = instance_cfg.get("ttl", "none")
        env = instance_cfg.get("env", "dev")
        owner = instance_cfg.get("owner", "unknown")
        user_data_path = instance_cfg.get("user_data")
        private_ip = instance_cfg.get("private_ip", None)
        associate_public_ip = instance_cfg.get("associate_public_ip", True)

        # ✅ User data
        user_data = None
        if user_data_path:
            expanded_path = os.path.expanduser(user_data_path)
            if os.path.exists(expanded_path):
                with open(expanded_path, "r") as f:
                    user_data = f.read()
            else:
                pulumi.log.warn(f"⚠️ user_data 文件不存在: {expanded_path}")

        tags = {
            "Name": name,
            "Lifecycle": lifecycle,
            "TTL": ttl,
            "Environment": env,
            "Owner": owner,
        }

        # ✅ Spot 实例配置
        instance_market_options = None
        if lifecycle == "spot":
            instance_market_options = aws.ec2.InstanceInstanceMarketOptionsArgs(
                market_type="spot",
                spot_options=aws.ec2.InstanceInstanceMarketOptionsSpotOptionsArgs(
                    instance_interruption_behavior="terminate",
                    spot_instance_type="one-time"
                )
            )

        # ✅ 解析 security group ids（通过名字）
        sg_names = instance_cfg.get("sg_names", [])
        security_group_ids = []
        for sg_name in sg_names:
            sg = sg_map.get(sg_name)
            if sg:
                security_group_ids.append(sg.id)
            else:
                pulumi.log.warn(f"⚠️ 实例 '{name}' 引用的 SG '{sg_name}' 未找到，已跳过")

        # ✅ 构建依赖项
        resource_dependencies = [subnet]
        for sg in security_group_ids:
            resource_dependencies.append(sg_map.get(sg_name))
        if depends_on:
            resource_dependencies.extend(depends_on)

        # ✅ 创建实例
        ec2 = aws.ec2.Instance(name,
            ami=ami,
            instance_type=instance_type,
            key_name=key_name,
            subnet_id=subnet_id,
            private_ip=private_ip,
            associate_public_ip_address=associate_public_ip,
            vpc_security_group_ids=security_group_ids,
            user_data=user_data,
            root_block_device={
                "volume_size": disk_size,
                "volume_type": "gp2"
            },
            instance_market_options=instance_market_options,
            tags=tags,
            opts=pulumi.ResourceOptions(depends_on=resource_dependencies)
        )

        outputs[name + "_id"] = ec2.id
        outputs[name + "_public_ip"] = ec2.public_ip
        outputs[name + "_private_ip"] = ec2.private_ip

    return outputs
