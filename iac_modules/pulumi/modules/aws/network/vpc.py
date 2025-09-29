from __future__ import annotations

from typing import Dict, List, Mapping, Optional

import pulumi
import pulumi_aws as aws

from ..common.tags import merge_tags


def create_vpc_topology(
    network_conf: Mapping[str, object],
    default_tags: Optional[Mapping[str, str]] = None,
) -> Dict[str, Dict[str, pulumi.Resource]]:
    """Provision VPCs, subnets, and routing components for the landing zone."""

    vpcs_conf = network_conf.get("vpcs", []) or []

    vpcs: Dict[str, aws.ec2.Vpc] = {}
    subnets: Dict[str, aws.ec2.Subnet] = {}
    internet_gateways: Dict[str, aws.ec2.InternetGateway] = {}
    route_tables: Dict[str, aws.ec2.RouteTable] = {}

    for vpc_conf in vpcs_conf:
        vpc_name = vpc_conf["name"]
        vpc_tags = merge_tags(default_tags, vpc_conf.get("tags"))
        vpc = aws.ec2.Vpc(
            vpc_name,
            cidr_block=vpc_conf["cidr_block"],
            enable_dns_support=vpc_conf.get("enable_dns_support", True),
            enable_dns_hostnames=vpc_conf.get("enable_dns_hostnames", True),
            **({"tags": vpc_tags} if vpc_tags else {}),
        )
        vpcs[vpc_name] = vpc

        subnets_by_type: Dict[str, List[aws.ec2.Subnet]] = {}
        has_public_subnet = False

        for subnet_conf in vpc_conf.get("subnets", []) or []:
            subnet_name = subnet_conf["name"]
            subnet_type = subnet_conf.get("type", "private")
            subnet_tags = merge_tags(vpc_tags, subnet_conf.get("tags"))
            subnet = aws.ec2.Subnet(
                subnet_name,
                vpc_id=vpc.id,
                cidr_block=subnet_conf["cidr_block"],
                map_public_ip_on_launch=subnet_type == "public",
                availability_zone=subnet_conf.get("availability_zone"),
                **({"tags": subnet_tags} if subnet_tags else {}),
                opts=pulumi.ResourceOptions(depends_on=[vpc]),
            )
            subnets[subnet_name] = subnet
            subnets_by_type.setdefault(subnet_type, []).append(subnet)
            if subnet_type == "public":
                has_public_subnet = True

        igw: Optional[aws.ec2.InternetGateway] = None
        if has_public_subnet:
            igw = aws.ec2.InternetGateway(
                f"{vpc_name}-igw",
                vpc_id=vpc.id,
                **({"tags": merge_tags(vpc_tags, {"Name": f"{vpc_name}-igw"})} if vpc_tags else {}),
                opts=pulumi.ResourceOptions(depends_on=[vpc]),
            )
            internet_gateways[vpc_name] = igw

        for route_conf in vpc_conf.get("routes", []) or []:
            subnet_type = route_conf["subnet_type"]
            route_table_name = f"{vpc_name}-{subnet_type}-rt"
            if route_table_name not in route_tables:
                route_table_tags = merge_tags(vpc_tags, {"Name": route_table_name})
                route_tables[route_table_name] = aws.ec2.RouteTable(
                    route_table_name,
                    vpc_id=vpc.id,
                    **({"tags": route_table_tags} if route_table_tags else {}),
                    opts=pulumi.ResourceOptions(depends_on=[vpc]),
                )
            route_table = route_tables[route_table_name]

            gateway_type = route_conf.get("gateway")
            gateway_id = None
            if gateway_type == "internet_gateway":
                if not igw:
                    pulumi.log.warn(
                        f"Route in VPC '{vpc_name}' references an internet gateway but none was created"
                    )
                else:
                    gateway_id = igw.id

            aws.ec2.Route(
                f"{route_table_name}-{route_conf['destination_cidr_block'].replace('/', '-')}",
                route_table_id=route_table.id,
                destination_cidr_block=route_conf["destination_cidr_block"],
                gateway_id=gateway_id,
                opts=pulumi.ResourceOptions(depends_on=[route_table] + ([igw] if gateway_id else [])),
            )

        for subnet_type, subnet_resources in subnets_by_type.items():
            route_table_name = f"{vpc_name}-{subnet_type}-rt"
            route_table = route_tables.get(route_table_name)
            if not route_table:
                continue
            for subnet in subnet_resources:
                aws.ec2.RouteTableAssociation(
                    f"{subnet._name}-assoc",
                    subnet_id=subnet.id,
                    route_table_id=route_table.id,
                    opts=pulumi.ResourceOptions(depends_on=[route_table, subnet]),
                )

    pulumi.export("vpc_ids", {name: vpc.id for name, vpc in vpcs.items()})
    pulumi.export("subnet_ids", {name: subnet.id for name, subnet in subnets.items()})

    return {
        "vpcs": vpcs,
        "subnets": subnets,
        "internet_gateways": internet_gateways,
        "route_tables": route_tables,
    }
