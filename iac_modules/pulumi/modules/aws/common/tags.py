from __future__ import annotations

from typing import Dict, Mapping, Optional


def merge_tags(*tag_sets: Optional[Mapping[str, str]]) -> Optional[Dict[str, str]]:
    """Merge multiple tag dictionaries while ignoring falsy values."""
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
    """Return a kwargs dictionary including merged tags when present."""
    tags = merge_tags(default_tags, resource_tags)
    return {"tags": tags} if tags else {}
