import pulumi_aws as aws

def create_instances(instances_config, subnets_dict, sg_id, key_name):
    outputs = {}

    for instance_cfg in instances_config:
        name = instance_cfg["name"]
        subnet_name = instance_cfg["subnet"]
        subnet_id = subnets_dict[subnet_name].id
        ami = instance_cfg["ami"]
        instance_type = instance_cfg["type"]
        disk_size = instance_cfg["disk_size_gb"]

        # 读取可选字段
        lifecycle = instance_cfg.get("lifecycle", "ondemand")  # 默认按需
        ttl = instance_cfg.get("ttl", "none")  # 默认无 TTL

        # 设置 EC2 标签
        tags = {
            "Name": name,
            "Lifecycle": lifecycle,
            "TTL": ttl,
        }

        # 如果是 Spot 实例，设置市场选项（不设 max_price → 自动出价）
        instance_market_options = None
        if lifecycle == "spot":
            instance_market_options = aws.ec2.InstanceInstanceMarketOptionsArgs(
                market_type="spot",
                spot_options=aws.ec2.InstanceInstanceMarketOptionsSpotOptionsArgs(
                    instance_interruption_behavior="terminate",
                    spot_instance_type="one-time"
                )
            )

        # 创建 EC2 实例
        ec2 = aws.ec2.Instance(name,
            ami=ami,
            instance_type=instance_type,
            key_name=key_name,
            subnet_id=subnet_id,
            vpc_security_group_ids=[sg_id],
            associate_public_ip_address=True,
            root_block_device={
                "volume_size": disk_size,
                "volume_type": "gp2"
            },
            instance_market_options=instance_market_options,
            tags=tags
        )

        outputs[name] = ec2.public_ip

    return outputs
