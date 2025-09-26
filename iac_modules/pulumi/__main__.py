from __future__ import annotations

import os
from typing import Dict

import pulumi
import pulumi_alicloud as alicloud

from modules import (
    create_oss_buckets,
    create_ram_identity,
    create_security_groups,
    create_vpc_topology,
    enable_actiontrail,
    enable_config_baseline,
)
from utils.config_loader import load_merged_config


def main() -> None:
    config_dir = os.environ.get("CONFIG_PATH", "config/alicloud")
    config = load_merged_config(config_dir)

    alicloud_conf: Dict[str, object] = config.get("alicloud", {})  # type: ignore[assignment]
    region = alicloud_conf.get("region")
    profile = alicloud_conf.get("profile")
    default_tags = alicloud_conf.get("default_tags", {})

    if region:
        alicloud.config.region = region
        pulumi.export("region", region)
    if profile:
        alicloud.config.profile = profile

    pulumi.log.info(
        "Loaded Alicloud configuration",
    )

    identity_results = create_ram_identity(config.get("identity", {}))

    buckets = create_oss_buckets(config.get("storage", {}), default_tags)

    network_results = create_vpc_topology(config.get("network", {}), default_tags)
    vpcs = network_results.get("vpcs", {})

    security_groups = create_security_groups(
        config.get("security", {}), vpcs, default_tags
    )

    enable_actiontrail(config.get("audit", {}), buckets)

    enable_config_baseline(config.get("config_service", {}), buckets)

    pulumi.export("ram_user_count", len(identity_results.get("users", {})))
    pulumi.export("security_group_count", len(security_groups))


if __name__ == "__main__":
    main()
