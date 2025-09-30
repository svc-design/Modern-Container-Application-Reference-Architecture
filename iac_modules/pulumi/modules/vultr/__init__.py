"""Reusable Vultr landing zone modules and deployment helpers."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any, Dict, Mapping, MutableMapping

import pulumi
import ediri_vultr as vultr

from utils.config_loader import load_merged_config
from .common import merge_tags
from .compute import create_instances
from .network import create_vpcs
from .security import create_firewall_groups

DEFAULT_CONFIG_DIR = Path(__file__).resolve().parents[4] / "config" / "vultr"


def resolve_config_directory(
    config_dir: str | os.PathLike[str] | None = None,
) -> Path:
    """Resolve the configuration directory for Vultr deployments.

    When ``config_dir`` is ``None`` the ``CONFIG_PATH`` environment variable is
    consulted and finally the repository default ``config/vultr`` directory is
    used.
    """

    if config_dir is not None:
        return Path(config_dir)

    env_dir = os.environ.get("CONFIG_PATH")
    if env_dir:
        return Path(env_dir)

    return DEFAULT_CONFIG_DIR


def load_configuration(config_dir: str | os.PathLike[str] | None = None) -> Dict[str, Any]:
    """Load and merge Vultr configuration files from ``config_dir``."""

    resolved_dir = resolve_config_directory(config_dir)
    return load_merged_config(str(resolved_dir))


def deploy_from_config(config: Mapping[str, Any]) -> Dict[str, Any]:
    """Deploy Vultr landing zone resources from an in-memory configuration."""

    vultr_conf: MutableMapping[str, Any] = {}
    vultr_section = config.get("vultr")
    if isinstance(vultr_section, MutableMapping):
        vultr_conf = vultr_section
    elif vultr_section is not None:
        pulumi.log.warn("'vultr' 配置段不是映射类型，将忽略其中的内容")

    region = vultr_conf.get("region")
    default_tags = vultr_conf.get("default_tags")

    if region:
        vultr.config.region = region  # type: ignore[assignment]
        pulumi.export("region", region)

    pulumi.log.info("Loaded Vultr configuration")

    network_results = create_vpcs(
        config.get("network", {}),
        region,
    )

    firewall_results = create_firewall_groups(
        config.get("security", {}),
    )

    instance_results = create_instances(
        config.get("compute", {}),
        region,
        default_tags if isinstance(default_tags, Mapping) else None,
        firewall_results,
        network_results,
    )

    pulumi.export("vpc_count", len(network_results))
    pulumi.export("firewall_group_count", len(firewall_results))
    pulumi.export("instance_count", len(instance_results))

    return {
        "network": network_results,
        "security": firewall_results,
        "compute": instance_results,
    }


def deploy_from_directory(
    config_dir: str | os.PathLike[str] | None = None,
) -> Dict[str, Any]:
    """Deploy Vultr landing zone resources from configuration files."""

    return deploy_from_config(load_configuration(config_dir))


__all__ = [
    "merge_tags",
    "create_instances",
    "create_vpcs",
    "create_firewall_groups",
    "resolve_config_directory",
    "load_configuration",
    "deploy_from_config",
    "deploy_from_directory",
]
