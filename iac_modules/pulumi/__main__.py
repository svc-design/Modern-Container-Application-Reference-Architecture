from __future__ import annotations

import os
from typing import Dict

import pulumi
import pulumi_aws as aws
import ediri_vultr as vultr
import pulumi_alicloud as alicloud

from modules import aws as aws_modules
from modules import vultr as vultr_modules
from modules import alicloud as alicloud_modules
from utils.config_loader import load_merged_config

def deploy_alicloud(config: Dict[str, object]) -> None:
    alicloud_conf: Dict[str, object] = config.get("alicloud", {})  # type: ignore[assignment]
    region = alicloud_conf.get("region")
    profile = alicloud_conf.get("profile")
    default_tags = alicloud_conf.get("default_tags", {})

    if region:
        alicloud.config.region = region  # type: ignore[assignment]
        pulumi.export("region", region)
    if profile:
        alicloud.config.profile = profile  # type: ignore[assignment]

    pulumi.log.info("Loaded Alicloud configuration")

    identity_results = alicloud_modules.create_ram_identity(
        config.get("identity", {}),
    )

    buckets = alicloud_modules.create_oss_buckets(
        config.get("storage", {}),
        default_tags,
    )

    network_results = alicloud_modules.create_vpc_topology(
        config.get("network", {}),
        default_tags,
    )
    vpcs = network_results.get("vpcs", {})

    security_groups = alicloud_modules.create_security_groups(
        config.get("security", {}),
        vpcs,
        default_tags,
    )

    alicloud_modules.enable_actiontrail(config.get("audit", {}), buckets)
    alicloud_modules.enable_config_baseline(config.get("config_service", {}), buckets)

    pulumi.export("ram_user_count", len(identity_results.get("users", {})))
    pulumi.export("security_group_count", len(security_groups))


def deploy_aws(config: Dict[str, object]) -> None:
    aws_conf: Dict[str, object] = config.get("aws", {})  # type: ignore[assignment]
    region = aws_conf.get("region")
    profile = aws_conf.get("profile")
    default_tags = aws_conf.get("default_tags", {})

    if region:
        aws.config.region = region  # type: ignore[assignment]
        pulumi.export("region", region)
    if profile:
        aws.config.profile = profile  # type: ignore[assignment]

    pulumi.log.info("Loaded AWS configuration")

    identity_results = aws_modules.create_iam_identity(
        config.get("identity", {}),
        default_tags,
    )

    buckets = aws_modules.create_s3_buckets(
        config.get("storage", {}),
        default_tags,
    )

    network_results = aws_modules.create_vpc_topology(
        config.get("network", {}),
        default_tags,
    )
    vpcs = network_results.get("vpcs", {})

    security_groups = aws_modules.create_security_groups(
        config.get("security", {}),
        vpcs,
        default_tags,
    )

    pulumi.export("iam_user_count", len(identity_results.get("users", {})))
    pulumi.export("security_group_count", len(security_groups))
    pulumi.export("s3_bucket_count", len(buckets))


def deploy_vultr(config: Dict[str, object]) -> None:
    vultr_conf: Dict[str, object] = config.get("vultr", {})  # type: ignore[assignment]
    region = vultr_conf.get("region")
    default_tags = vultr_conf.get("default_tags", {})

    if region:
        vultr.config.region = region  # type: ignore[assignment]
        pulumi.export("region", region)

    pulumi.log.info("Loaded Vultr configuration")

    network_results = vultr_modules.create_vpcs(
        config.get("network", {}),
        region,
    )

    firewall_results = vultr_modules.create_firewall_groups(
        config.get("security", {}),
    )

    instance_results = vultr_modules.create_instances(
        config.get("compute", {}),
        region,
        default_tags,
        firewall_results,
        network_results,
    )

    pulumi.export("vpc_count", len(network_results))
    pulumi.export("firewall_group_count", len(firewall_results))
    pulumi.export("instance_count", len(instance_results))


def main() -> None:
    config_dir = os.environ.get("CONFIG_PATH", "config/alicloud")
    config = load_merged_config(config_dir)

    if "alicloud" in config:
        deploy_alicloud(config)
    elif "aws" in config:
        deploy_aws(config)
    elif "vultr" in config:
        deploy_vultr(config)
    else:
        raise ValueError(
            "Unsupported landing zone configuration. Expected a 'alicloud', 'aws', or 'vultr' section."
        )


if __name__ == "__main__":
    main()
