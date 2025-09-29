from __future__ import annotations

from typing import Dict, Iterable, Mapping, Optional

import pulumi
import pulumi_aws as aws

from ..common.tags import merge_tags


def _build_transitions(transitions_conf: Optional[Iterable[Mapping[str, object]]]):
    transitions = []
    for transition in transitions_conf or []:
        if "storage_class" not in transition:
            continue
        transitions.append(
            aws.s3.BucketLifecycleRuleTransitionArgs(
                storage_class=str(transition["storage_class"]),
                days=transition.get("days"),
            )
        )
    return transitions or None


def _build_lifecycle_rules(lifecycle_conf: Optional[Iterable[Mapping[str, object]]]):
    rules = []
    for rule in lifecycle_conf or []:
        expiration_days = rule.get("expiration_days")
        expiration = (
            aws.s3.BucketLifecycleRuleExpirationArgs(days=int(expiration_days))
            if expiration_days is not None
            else None
        )
        rules.append(
            aws.s3.BucketLifecycleRuleArgs(
                id=rule.get("id"),
                enabled=rule.get("enabled", True),
                prefix=rule.get("prefix"),
                transitions=_build_transitions(rule.get("transitions")),
                expiration=expiration,
            )
        )
    return rules or None


def _build_encryption(encryption_conf: Optional[Mapping[str, object]]):
    if not encryption_conf:
        return None
    return aws.s3.BucketServerSideEncryptionConfigurationArgs(
        rules=[
            aws.s3.BucketServerSideEncryptionConfigurationRuleArgs(
                apply_server_side_encryption_by_default=
                aws.s3.BucketServerSideEncryptionConfigurationRuleApplyServerSideEncryptionByDefaultArgs(
                    sse_algorithm=encryption_conf.get("sse_algorithm", "AES256"),
                    kms_master_key_id=encryption_conf.get("kms_master_key_id"),
                )
            )
        ]
    )


def create_s3_buckets(
    storage_conf: Mapping[str, object],
    default_tags: Optional[Mapping[str, str]] = None,
) -> Dict[str, aws.s3.Bucket]:
    """Provision baseline S3 buckets for the landing zone."""

    buckets_conf = storage_conf.get("buckets", []) or []
    buckets: Dict[str, aws.s3.Bucket] = {}

    for bucket_conf in buckets_conf:
        name = bucket_conf["name"]
        bucket_tags = merge_tags(default_tags, bucket_conf.get("tags"))
        versioning_enabled = bucket_conf.get("versioning", True)
        bucket = aws.s3.Bucket(
            name,
            bucket=bucket_conf.get("bucket", name),
            acl=bucket_conf.get("acl", "private"),
            force_destroy=bucket_conf.get("force_destroy", False),
            versioning=aws.s3.BucketVersioningArgs(enabled=bool(versioning_enabled)),
            lifecycle_rules=_build_lifecycle_rules(bucket_conf.get("lifecycle_rules")),
            server_side_encryption_configuration=_build_encryption(
                bucket_conf.get("server_side_encryption")
            ),
            **({"tags": bucket_tags} if bucket_tags else {}),
        )
        buckets[name] = bucket

        if bucket_conf.get("block_public_access", True):
            aws.s3.BucketPublicAccessBlock(
                f"{name}-public-access-block",
                bucket=bucket.id,
                block_public_acls=True,
                block_public_policy=True,
                ignore_public_acls=True,
                restrict_public_buckets=True,
                opts=pulumi.ResourceOptions(depends_on=[bucket]),
            )

    pulumi.export("s3_buckets", {name: bucket.id for name, bucket in buckets.items()})
    return buckets
