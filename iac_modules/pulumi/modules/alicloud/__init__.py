from __future__ import annotations

from .audit.actiontrail import enable_actiontrail
from .config_service.baseline import enable_config_baseline
from .identity.ram import create_ram_identity
from .network.vpc import create_vpc_topology
from .security.security_groups import create_security_groups
from .storage.oss import create_oss_buckets

__all__ = [
    "enable_actiontrail",
    "enable_config_baseline",
    "create_ram_identity",
    "create_vpc_topology",
    "create_security_groups",
    "create_oss_buckets",
]
