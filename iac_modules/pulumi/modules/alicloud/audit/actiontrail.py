from __future__ import annotations

from typing import Mapping, Optional

import pulumi
import pulumi_alicloud as alicloud


def enable_actiontrail(
    audit_conf: Mapping[str, object],
    buckets: Mapping[str, pulumi.Resource],
) -> Optional[pulumi.Resource]:
    trail_conf = audit_conf.get("actiontrail") if audit_conf else None
    if not trail_conf:
        pulumi.log.info("ActionTrail configuration not provided; skipping setup")
        return None

    if not trail_conf.get("enabled", True):
        pulumi.log.info("ActionTrail disabled via configuration; skipping setup")
        return None

    bucket_name = trail_conf.get("oss_bucket_name")
    bucket_reference = trail_conf.get("oss_bucket_ref")
    if not bucket_name and bucket_reference:
        bucket = buckets.get(bucket_reference)
        if bucket is None:
            pulumi.log.warn(
                f"ActionTrail bucket reference '{bucket_reference}' could not be resolved"
            )
        else:
            bucket_name = bucket.bucket

    if not bucket_name:
        pulumi.log.warn("No OSS bucket specified for ActionTrail; skipping trail creation")
        return None

    name = trail_conf.get("name", "landingzone-actiontrail")
    trail = alicloud.actiontrail.Trail(
        name,
        trail_name=trail_conf.get("trail_name", name),
        event_rw=trail_conf.get("event_rw", "All"),
        oss_bucket_name=bucket_name,
        oss_key_prefix=trail_conf.get("oss_key_prefix"),
        trail_region=trail_conf.get("trail_region"),
        is_organization_trail=trail_conf.get("is_organization_trail"),
        oss_write_role_arn=trail_conf.get("oss_write_role_arn"),
        sls_project_arn=trail_conf.get("sls_project_arn"),
        sls_write_role_arn=trail_conf.get("sls_write_role_arn"),
        status=trail_conf.get("status"),
    )

    pulumi.export("actiontrail_trail", trail.trail_name)
    return trail
