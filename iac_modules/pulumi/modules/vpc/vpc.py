import pulumi_aws as aws
import pulumi

def create_vpc(vpc_conf, region):
    # 1. VPC
    vpc = aws.ec2.Vpc(vpc_conf['name'],
        cidr_block=vpc_conf['cidr_block'],
        tags={"Name": vpc_conf['name']}
    )

    # 2. Internet Gateway（若有 public 子网）
    has_public = any(subnet["type"] == "public" for subnet in vpc_conf["subnets"])
    igw = aws.ec2.InternetGateway("main-igw", vpc_id=vpc.id) if has_public else None

    # 3. 子网
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

    # 4. 路由表（仅 public 支持）
    if has_public:
        rt = aws.ec2.RouteTable("public-route-table",
            vpc_id=vpc.id,
            routes=[{
                "cidr_block": r["destination_cidr_block"],
                "gateway_id": igw.id
            } for r in vpc_conf.get("routes", []) if r["subnet_type"] == "public"]
        )

        # 关联 public 子网
        for subnet_cfg in vpc_conf["subnets"]:
            if subnet_cfg["type"] == "public":
                aws.ec2.RouteTableAssociation(f"{subnet_cfg['name']}-assoc",
                    subnet_id=subnets[subnet_cfg["name"]].id,
                    route_table_id=rt.id
                )

    # 5. TODO: peering 支持（预留接口）
    # if vpc_conf.get("peering", {}).get("enabled"):
    #     ...

    return {
        "vpc": vpc,
        "subnets": subnets,
        "igw": igw
    }
