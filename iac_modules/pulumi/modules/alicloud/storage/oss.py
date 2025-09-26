from __future__ import annotations

from typing import Dict, List, Mapping, Optional

import pulumi
import pulumi_alicloud as alicloud

from ..common.tags import merge_tags


LifecycleConfig = Mapping[str, object]


def create_oss_buckets(
    storage_conf: Mapping[str, object],
    default_tags: Optional[Mapping[str, str]] = None,
) -> Dict[str, pulumi.Resource]:
    buckets_conf = storage_conf.get("oss_buckets", []) or []
    buckets: Dict[str, pulumi.Resource] = {}

    for bucket_conf in buckets_conf:
        name = bucket_conf["name"]
        tags = merge_tags(default_tags, bucket_conf.get("tags"))
        lifecycle_rules = [_build_lifecycle_rule(rule) for rule in bucket_conf.get("lifecycle_rules", [])]
        lifecycle_rules = [rule for rule in lifecycle_rules if rule is not None]

        bucket = alicloud.oss.Bucket(
            name,
            bucket=bucket_conf.get("bucket", name),
            storage_class=bucket_conf.get("storage_class", "Standard"),
            acl=bucket_conf.get("acl"),
            force_destroy=bucket_conf.get("force_destroy", False),
            logging=_build_logging(bucket_conf.get("logging")),
            versioning=_build_versioning(bucket_conf.get("versioning")),
            lifecycle_rules=lifecycle_rules or None,
            **({"tags": tags} if tags else {}),
        )
        buckets[name] = bucket

    pulumi.export("oss_bucket_names", {name: bucket.bucket for name, bucket in buckets.items()})
    return buckets


def _build_versioning(config: Optional[Mapping[str, object]]) -> Optional[alicloud.oss.BucketVersioningArgs]:
    if not config:
        return None
    if isinstance(config, str):
        status = config
    else:
        status = config.get("status", "Enabled")
    return alicloud.oss.BucketVersioningArgs(status=status)


def _build_logging(config: Optional[Mapping[str, object]]) -> Optional[alicloud.oss.BucketLoggingArgs]:
    if not config:
        return None
    target_bucket = config.get("target_bucket")
    if not target_bucket:
        return None
    return alicloud.oss.BucketLoggingArgs(
        target_bucket=target_bucket,
        target_prefix=config.get("target_prefix"),
    )


def _build_lifecycle_rule(config: LifecycleConfig) -> Optional[alicloud.oss.BucketLifecycleRuleArgs]:
    if not config:
        return None

    transitions = [
        alicloud.oss.BucketLifecycleRuleTransitionArgs(
            storage_class=transition["storage_class"],
            days=transition.get("days"),
            created_before_date=transition.get("created_before_date"),
            is_access_time=transition.get("is_access_time"),
            return_to_std_when_visit=transition.get("return_to_standard_when_visited"),
        )
        for transition in config.get("transitions", [])
        if "storage_class" in transition
    ]

    expiration_cfg = config.get("expiration")
    if expiration_cfg is None and config.get("expiration_days"):
        expiration_cfg = {"days": config["expiration_days"]}

    expirations: List[alicloud.oss.BucketLifecycleRuleExpirationArgs] = []
    if expiration_cfg:
        expirations.append(
            alicloud.oss.BucketLifecycleRuleExpirationArgs(
                days=expiration_cfg.get("days"),
                date=expiration_cfg.get("date"),
                created_before_date=expiration_cfg.get("created_before_date"),
                expired_object_delete_marker=expiration_cfg.get("expired_object_delete_marker"),
            )
        )

    return alicloud.oss.BucketLifecycleRuleArgs(
        id=config.get("id"),
        enabled=config.get("enabled", True),
        prefix=config.get("prefix"),
        transitions=transitions or None,
        expirations=expirations or None,
    )
