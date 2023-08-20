import pulumi
import pulumi_aws

#-----------global vars---------------#
stack_name = pulumi.get_stack()
project_name = pulumi.get_project()
#------------------------------------#
def vpc():
    vpc = pulumi_aws.ec2.Vpc(
            resource_name=f"eks-{project_name}-{stack_name}",
            cidr_block="10.100.0.0/16",
            enable_dns_support=True,
            enable_dns_hostnames=True,
            instance_tenancy='default',
            tags={
                  "Project": project_name,
                  "Stack": stack_name
                  }
            )
    return vpc.id
#------------------------------------#
def key_pair( resource_name: str, public_key: str ):
    key_pair = pulumi_aws.ec2.KeyPair( resource_name=resource_name, public_key=public_key )
    return key_pair.key_name
#------------------------------------#
def ec2( arch, ec2_name, ec2_type, key_name, subnet_id, security_group_id ):
    if arch == 'amd64':
        ami = pulumi_aws.ec2.get_ami(
                owners = ["099720109477"],
                filters = [
                    pulumi_aws.ec2.GetAmiFilterArgs(
                        name = "name",
                        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
                    )],
                most_recent = True)

    if arch == 'arm64':
        ami = pulumi_aws.ec2.get_ami(
                owners = ["099720109477"],
                filters = [
                    pulumi_aws.ec2.GetAmiFilterArgs(
                        name = "name",
                        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
                    )],
                most_recent = True)

    root_ebs = {
            "deleteOnTermination": True,
            "volume_size": 100,
            "volumeType": 'gp3',
            "encrypted": False
            }

    instance = pulumi_aws.ec2.Instance(
            ami=ami.id,
            resource_name = ec2_name,
            instance_type = ec2_type,
            key_name      = key_name,
            subnet_id     = subnet_id,
            root_block_device = root_ebs,
            vpc_security_group_ids = [ security_group_id ],
            tags = {
                "Name": ec2_name
                }
            )
    return instance
#------------------------------------#
def availability_zones():
    az_list = pulumi_aws.get_availability_zones(state="available").names
    return az_list
#------------------------------------#
def internet_gateway( vpc_id ):
    igw = pulumi_aws.ec2.InternetGateway(
            resource_name=f'vpc-igw-{project_name}-{stack_name}',
            vpc_id=vpc_id,
            tags={
                "Project": project_name,
                "Stack": stack_name
                }
            )
    return igw.id

#------------------------------------#
def route_table( vpc_id, igw_id ):
    route_table = pulumi_aws.ec2.RouteTable(
            resource_name = f'vpc-route-table-{project_name}-{stack_name}',
            vpc_id = vpc_id,
            routes = [
                pulumi_aws.ec2.RouteTableRouteArgs(
                    cidr_block='0.0.0.0/0',
                    gateway_id=igw_id
                  )
                ],
            tags = {
                "Project": project_name,
                "Stack": stack_name
                }
            )
    return route_table.id

#------------------------------------#
def security_group( vpc_id ):
    security_group = pulumi_aws.ec2.SecurityGroup(
            resource_name = f'ec2-default-sg-{project_name}-{stack_name}',
            vpc_id = vpc_id,
            description = "Allow all HTTP(s) traffic to EKS Cluster",
            ingress = [
                pulumi_aws.ec2.SecurityGroupIngressArgs(
                    protocol='tcp',
                    from_port=22,
                    to_port=22,
                    cidr_blocks=['0.0.0.0/0'],
                    description='Allow sshd connect'),
                pulumi_aws.ec2.SecurityGroupIngressArgs(
                    protocol='tcp',
                    from_port=80,
                    to_port=80,
                    cidr_blocks=['0.0.0.0/0'],
                    description='Allow http 80'),
                pulumi_aws.ec2.SecurityGroupIngressArgs(
                    protocol='tcp',
                    from_port=389,
                    to_port=389,
                    cidr_blocks=['0.0.0.0/0'],
                    description='Allow LDAP 389'),
                pulumi_aws.ec2.SecurityGroupIngressArgs(
                    protocol='tcp',
                    from_port=443,
                    to_port=443,
                    cidr_blocks=['0.0.0.0/0'],
                    description='Allow https 443')
                   ],
            egress=[
                pulumi_aws.ec2.SecurityGroupEgressArgs(
                    from_port=0,
                    to_port=0,
                    protocol="-1",
                    cidr_blocks=["0.0.0.0/0"]
                    )],
            tags = {
                "Project": project_name,
                "Stack": stack_name
                }
            )
    return security_group.id

#------------------------------------#
def subnets( vpc_id, az_name, route_table_id, net_type='private' ):

# If you wanted to double the number of subnets because you have few
# availability zones, you can redefine the variable below to something
# like: list(itertools.chain(azs, azs)) which would just repeat the
# same list of AZs twice. The iteration logic will pick it up for
# subnet creation and create unique names.

    subnets = []

    az_list = availability_zones()
    az_enum = list(az_list)

    if len(az_list) <= 0:
        raise ValueError("There are no usable availability zones")
    if len(az_list) == 1:
        pulumi.log.warn("There is only a single usable availability zone")
    elif len(az_list) == 2:
        pulumi.log.warn("There are only two usable availability zones")

    for i, az in enumerate(az_enum):

        if net_type == 'public':
            subnet_addr = i
            map_eip=True
        if net_type == 'private':
            subnet_addr = (i + 1) * 16
            map_eip=False

        if not isinstance(az, str):
            raise f'availability zone specified [{i}] is not a valid string value: [{az}]'
        if az.strip() == "":
            raise f'availability zone specified [{i}] is an empty string'

        subnet_instance = pulumi_aws.ec2.Subnet(
                resource_name = f'{az}-{net_type}-{project_name}-{stack_name}-{i}',
                vpc_id=vpc_id,
                availability_zone=az,
                cidr_block=f"10.100.{subnet_addr}.0/24",
                map_public_ip_on_launch=map_eip,
                tags={
                    "Project": project_name,
                    "Stack": stack_name,
                    }
                )
        pulumi_aws.ec2.RouteTableAssociation(
                f"route-table-assoc-{net_type}-{az}-{i}",
                route_table_id=route_table_id,
                subnet_id=subnet_instance.id
                )
        subnets.append(subnet_instance.id)

    return subnets
