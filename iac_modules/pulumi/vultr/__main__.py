from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Any, Dict

import pulumi
import ediri_vultr as vultr

# 允许导入共享的工具模块
PROJECT_DIR = Path(__file__).resolve().parent
PULUMI_ROOT = PROJECT_DIR.parent
REPO_ROOT = PULUMI_ROOT.parent.parent
sys.path.append(str(PULUMI_ROOT))

from utils.config_loader import load_merged_config  # noqa: E402
from vultr.modules import create_firewall_groups, create_instances, create_vpcs  # noqa: E402


def main() -> None:
    default_config_dir = REPO_ROOT / "config" / "vultr"
    config_dir = os.environ.get("CONFIG_PATH", str(default_config_dir))

    config = load_merged_config(config_dir)

    vultr_conf: Dict[str, Any] = config.get("vultr", {})  # type: ignore[assignment]
    region = vultr_conf.get("region")
    default_tags = vultr_conf.get("default_tags", {})

    if region:
        vultr.config.region = region
        pulumi.export("region", region)

    pulumi.log.info("Loaded Vultr configuration")

    network_results = create_vpcs(config.get("network", {}), region)
    firewall_results = create_firewall_groups(config.get("security", {}))
    instance_results = create_instances(
        config.get("compute", {}),
        region,
        default_tags,
        firewall_results,
        network_results,
    )

    pulumi.export("vpc_count", len(network_results))
    pulumi.export("firewall_group_count", len(firewall_results))
    pulumi.export("instance_count", len(instance_results))


if __name__ == "__main__":
    main()
