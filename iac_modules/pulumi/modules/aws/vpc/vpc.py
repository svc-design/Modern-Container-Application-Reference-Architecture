import pulumi_aws as aws
import pulumi

def create_vpcs(vpc_list, region):
    results = {}
    for vpc_conf in vpc_list:
        result = create_vpc(vpc_conf, region)
        results[vpc_conf["name"]] = result
    return results

def create_vpc(vpc_conf, region):
    vpc = aws.ec2.Vpc(vpc_conf['name'],
        cidr_block=vpc_conf['cidr_block'],
        enable_dns_support=True,
        enable_dns_hostnames=True,
        tags={"Name": vpc_conf['name']}
    )

    # 判断是否包含公有子网
    has_public = any(subnet["type"] == "public" for subnet in vpc_conf["subnets"])
    igw = aws.ec2.InternetGateway(f"{vpc_conf['name']}-igw", vpc_id=vpc.id) if has_public else None

    subnets = {}
    for subnet_cfg in vpc_conf["subnets"]:
        subnet = aws.ec2.Subnet(subnet_cfg["name"],
            vpc_id=vpc.id,
            cidr_block=subnet_cfg["cidr_block"],
            map_public_ip_on_launch=subnet_cfg["type"] == "public",
            availability_zone=subnet_cfg["availability_zone"],
            tags={"Name": subnet_cfg["name"]}
        )
        subnets[subnet_cfg["name"]] = subnet

    # 路由表创建，根据 subnet_type 分组
    route_tables = {}

    if "routes" in vpc_conf:
        for route_cfg in vpc_conf["routes"]:
            subnet_type = route_cfg["subnet_type"]
            route_table_name = f"{vpc_conf['name']}-{subnet_type}-rt"

            # 如果还未创建该类型的路由表，则创建
            if subnet_type not in route_tables:
                route_table = aws.ec2.RouteTable(route_table_name,
                    vpc_id=vpc.id,
                    routes=[],
                    tags={"Name": route_table_name}
                )
                route_tables[subnet_type] = route_table
            else:
                route_table = route_tables[subnet_type]

            # 添加路由条目（追加）
            aws.ec2.Route(f"{route_table_name}-{route_cfg['destination_cidr_block'].replace('/', '-')}",
                route_table_id=route_table.id,
                destination_cidr_block=route_cfg["destination_cidr_block"],
                gateway_id=igw.id if route_cfg["gateway"] == "internet_gateway" else None
            )

    # 路由表关联到子网
    for subnet_cfg in vpc_conf["subnets"]:
        subnet_type = subnet_cfg["type"]
        if subnet_type in route_tables:
            aws.ec2.RouteTableAssociation(f"{subnet_cfg['name']}-assoc",
                subnet_id=subnets[subnet_cfg["name"]].id,
                route_table_id=route_tables[subnet_type].id
            )

    # TODO: Peering 支持

    return {
        "vpc": vpc,
        "subnets": subnets,
        "igw": igw,
        "route_tables": route_tables
    }
