"""Vultr landing zone baseline Pulumi modules."""

from modules.vultr import (  # re-export for backwards compatibility
    create_firewall_groups,
    create_instances,
    create_vpcs,
    merge_tags,
)

__all__ = [
    "merge_tags",
    "create_firewall_groups",
    "create_instances",
    "create_vpcs",
]
