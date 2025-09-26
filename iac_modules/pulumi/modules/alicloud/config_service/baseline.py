from __future__ import annotations

from typing import Dict, Mapping

import pulumi
import pulumi_alicloud as alicloud


def enable_config_baseline(
    config_conf: Mapping[str, object],
    buckets: Mapping[str, pulumi.Resource],
) -> Dict[str, object]:
    if not config_conf:
        pulumi.log.info("Cloud Config configuration not provided; skipping setup")
        return {}

    resources: Dict[str, object] = {}

    recorder_conf = config_conf.get("recorder")
    recorder = None
    if recorder_conf:
        recorder = alicloud.cfg.ConfigurationRecorder(
            recorder_conf.get("name", "config-recorder"),
            enterprise_edition=recorder_conf.get("enterprise_edition"),
            resource_types=recorder_conf.get("resource_types"),
        )
        resources["recorder"] = recorder

    delivery_conf = config_conf.get("delivery_channel")
    delivery_channel = None
    if delivery_conf:
        target_arn = delivery_conf.get("target_arn")
        bucket_ref = delivery_conf.get("oss_bucket_ref")
        if not target_arn and bucket_ref:
            bucket = buckets.get(bucket_ref)
            if bucket:
                target_arn = delivery_conf.get("target_arn_fallback")
                pulumi.log.info(
                    "Delivery channel target ARN not provided explicitly; using fallback"
                )
            else:
                pulumi.log.warn(
                    f"Delivery channel bucket reference '{bucket_ref}' could not be resolved"
                )
        if target_arn:
            delivery_channel = alicloud.cfg.DeliveryChannel(
                delivery_conf.get("name", "config-delivery-channel"),
                delivery_channel_name=delivery_conf.get("display_name"),
                description=delivery_conf.get("description"),
                delivery_channel_type=delivery_conf.get("type", "OSS"),
                delivery_channel_target_arn=target_arn,
                delivery_channel_assume_role_arn=delivery_conf.get("assume_role_arn"),
                delivery_channel_condition=delivery_conf.get("condition"),
                status=delivery_conf.get("status"),
            )
            resources["delivery_channel"] = delivery_channel
        else:
            pulumi.log.warn("Cloud Config delivery channel requires a target ARN; skipping")

    for rule_conf in config_conf.get("rules", []) or []:
        required_fields = ["name", "source_identifier"]
        if any(field not in rule_conf for field in required_fields):
            pulumi.log.warn(
                f"Skipping Cloud Config rule definition due to missing fields: {rule_conf}"
            )
            continue

        rule_args = {
            "rule_name": rule_conf["name"],
            "description": rule_conf.get("description"),
            "risk_level": rule_conf.get("risk_level", 2),
            "source_owner": rule_conf.get("source_owner", "ALIYUN"),
            "source_identifier": rule_conf["source_identifier"],
            "config_rule_trigger_types": rule_conf.get(
                "trigger_types", "ConfigurationItemChangeNotification"
            ),
            "resource_types_scopes": rule_conf.get("resource_types_scopes"),
            "region_ids_scope": rule_conf.get("region_ids_scope"),
            "resource_group_ids_scope": rule_conf.get("resource_group_ids_scope"),
            "tag_key_scope": rule_conf.get("tag_key_scope"),
            "tag_value_scope": rule_conf.get("tag_value_scope"),
            "input_parameters": rule_conf.get("input_parameters"),
            "maximum_execution_frequency": rule_conf.get("maximum_execution_frequency"),
            "status": rule_conf.get("status"),
        }
        rule_args = {key: value for key, value in rule_args.items() if value is not None}
        if delivery_channel:
            rule_args["delivery_channel_id"] = delivery_channel.id
        if recorder:
            rule_args["configuration_recorder_id"] = recorder.id

        rule = alicloud.cfg.Rule(rule_conf["name"], **rule_args)
        resources.setdefault("rules", {})[rule_conf["name"]] = rule

    return resources
