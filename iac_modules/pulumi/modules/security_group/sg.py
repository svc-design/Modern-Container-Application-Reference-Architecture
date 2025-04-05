import pulumi_aws as aws
from pulumi_aws.ec2 import SecurityGroup, SecurityGroupIngressArgs, SecurityGroupEgressArgs

def create_security_group(vpc_id: str, rule_config: dict) -> SecurityGroup:
    """
    创建 Security Group，支持 ingress/egress 配置，包括 TCP, UDP, ICMP
    :param vpc_id: 目标 VPC ID
    :param rule_config: 单个 firewall_rules 的字典配置
    :return: 创建的 SecurityGroup 资源对象
    """
    ingress_rules = []

    source_ranges = rule_config.get("source_ranges", ["0.0.0.0/0"])
    egress_ranges = rule_config.get("egress_ranges", ["0.0.0.0/0"])

    for allow_rule in rule_config.get("allow", []):
        protocol = allow_rule.get("protocol", "tcp").lower()
        ports = allow_rule.get("ports", [])

        # ICMP 无需端口处理
        if protocol == "icmp":
            ingress_rules.append(
                SecurityGroupIngressArgs(
                    protocol="icmp",
                    from_port=-1,
                    to_port=-1,
                    cidr_blocks=source_ranges
                )
            )
            continue

        # 处理 TCP/UDP 等需要端口的协议
        for port in ports:
            if isinstance(port, str) and port.lower() in ["*", "any", "all"]:
                from_port, to_port = 0, 65535
            else:
                port = int(port)
                from_port = to_port = port

            ingress_rules.append(
                SecurityGroupIngressArgs(
                    protocol=protocol,
                    from_port=from_port,
                    to_port=to_port,
                    cidr_blocks=source_ranges
                )
            )

    # 创建 Security Group
    sg = aws.ec2.SecurityGroup(
        rule_config.get("name", "default-sg"),
        vpc_id=vpc_id,
        description=f"Security Group: {rule_config.get('name', 'N/A')}",
        ingress=ingress_rules,
        egress=[
            SecurityGroupEgressArgs(
                protocol="-1",
                from_port=0,
                to_port=0,
                cidr_blocks=egress_ranges
            )
        ],
        tags={"Name": rule_config.get("name", "default-sg")}
    )

    return sg
