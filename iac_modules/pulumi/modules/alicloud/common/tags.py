from __future__ import annotations

from typing import Dict, Mapping, Optional

import pulumi


def merge_tags(*tag_sets: Optional[Mapping[str, str]]) -> Optional[Dict[str, str]]:
    """Merge multiple tag dictionaries while filtering out falsy values."""
    merged: Dict[str, str] = {}
    for tags in tag_sets:
        if not tags:
            continue
        for key, value in tags.items():
            if value is None:
                continue
            merged[str(key)] = str(value)
    return merged or None


def taggable_args(
    default_tags: Optional[Mapping[str, str]],
    resource_tags: Optional[Mapping[str, str]] = None,
) -> Dict[str, object]:
    """Helper to build Pulumi args with merged tags."""
    tags = merge_tags(default_tags, resource_tags)
    return {"tags": tags} if tags else {}


def annotate_resource_with_tags(resource: pulumi.CustomResource, tags: Optional[Mapping[str, str]]) -> None:
    """Attach merged tags to the Pulumi resource options after creation."""
    if tags:
        pulumi.export(f"tags::{resource._name}", tags)
