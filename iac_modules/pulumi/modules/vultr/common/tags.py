"""Tag helpers for Vultr resources."""

from __future__ import annotations

from typing import Iterable, List, Mapping, Optional


def merge_tags(
    default_tags: Optional[Mapping[str, str]] = None,
    resource_tags: Optional[object] = None,
) -> Optional[List[str]]:
    """Merge tag mappings or sequences into the Vultr key:value list format.

    Vultr expects tags to be provided as a list of strings. This helper accepts a
    combination of dictionaries, sequences of strings, or ``None`` and produces a
    normalised list ready for the Pulumi provider.
    """

    merged: List[str] = []

    if default_tags:
        merged.extend(f"{key}:{value}" for key, value in default_tags.items() if value is not None)

    if isinstance(resource_tags, Mapping):
        merged.extend(f"{key}:{value}" for key, value in resource_tags.items() if value is not None)
    elif isinstance(resource_tags, Iterable) and not isinstance(resource_tags, (str, bytes)):
        merged.extend(str(tag) for tag in resource_tags)
    elif resource_tags is not None:
        merged.append(str(resource_tags))

    return list(dict.fromkeys(merged)) or None
