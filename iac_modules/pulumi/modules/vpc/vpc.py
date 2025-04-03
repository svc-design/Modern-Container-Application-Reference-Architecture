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
        tags={"Name": vpc_conf['name']}
    )

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

    if has_public and "routes" in vpc_conf:
        rt = aws.ec2.RouteTable(f"{vpc_conf['name']}-public-rt",
            vpc_id=vpc.id,
            routes=[{
                "cidr_block": r["destination_cidr_block"],
                "gateway_id": igw.id
            } for r in vpc_conf["routes"] if r["subnet_type"] == "public"]
        )

        for subnet_cfg in vpc_conf["subnets"]:
            if subnet_cfg["type"] == "public":
                aws.ec2.RouteTableAssociation(f"{subnet_cfg['name']}-assoc",
                    subnet_id=subnets[subnet_cfg["name"]].id,
                    route_table_id=rt.id
                )

    # TODO: Peering 支持
    return {
        "vpc": vpc,
        "subnets": subnets,
        "igw": igw
    }
