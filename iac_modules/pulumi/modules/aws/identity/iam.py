from __future__ import annotations

from typing import Dict, Iterable, Mapping, Optional

import pulumi
import pulumi_aws as aws

from ..common.tags import merge_tags

PolicyConfig = Mapping[str, str]


def _normalize_policies(policies: Optional[Iterable[PolicyConfig]]) -> Iterable[PolicyConfig]:
    return policies or []


def _resolve_policy_arn(policy: PolicyConfig) -> Optional[str]:
    arn = policy.get("arn")
    if arn:
        return arn
    name = policy.get("name")
    if name:
        policy_type = policy.get("type", "aws")
        partition = policy.get("partition", "aws")
        if policy_type.lower() == "aws":
            return f"arn:{partition}:iam::aws:policy/{name}"
        elif policy_type.lower() == "customer" and "account" in policy:
            account = policy["account"]
            return f"arn:{partition}:iam::{account}:policy/{name}"
    pulumi.log.warn(
        f"IAM policy reference {policy} is missing a resolvable ARN; skipping attachment"
    )
    return None


def create_iam_identity(
    identity_conf: Mapping[str, object],
    default_tags: Optional[Mapping[str, str]] = None,
) -> Dict[str, Dict[str, pulumi.Resource]]:
    """Create IAM users, groups, and policy attachments from configuration."""

    default_path = identity_conf.get("default_path", "/")
    users_conf = identity_conf.get("users", []) or []
    groups_conf = identity_conf.get("groups", []) or []

    users: Dict[str, aws.iam.User] = {}
    groups: Dict[str, aws.iam.Group] = {}

    for user_conf in users_conf:
        name = user_conf["name"]
        path = user_conf.get("path", default_path)
        tags = merge_tags(default_tags, user_conf.get("tags"))
        user = aws.iam.User(
            name,
            name=name,
            path=path,
            force_destroy=user_conf.get("force_destroy", False),
            **({"tags": tags} if tags else {}),
        )
        users[name] = user

        for index, policy in enumerate(_normalize_policies(user_conf.get("policies"))):
            policy_arn = _resolve_policy_arn(policy)
            if not policy_arn:
                continue
            aws.iam.UserPolicyAttachment(
                f"{name}-policy-{index}",
                user=user.name,
                policy_arn=policy_arn,
                opts=pulumi.ResourceOptions(depends_on=[user]),
            )

    for group_conf in groups_conf:
        name = group_conf["name"]
        path = group_conf.get("path", default_path)
        tags = merge_tags(default_tags, group_conf.get("tags"))
        group = aws.iam.Group(
            name,
            name=name,
            path=path,
            **({"tags": tags} if tags else {}),
        )
        groups[name] = group

        for index, policy in enumerate(_normalize_policies(group_conf.get("policies"))):
            policy_arn = _resolve_policy_arn(policy)
            if not policy_arn:
                continue
            aws.iam.GroupPolicyAttachment(
                f"{name}-policy-{index}",
                group=group.name,
                policy_arn=policy_arn,
                opts=pulumi.ResourceOptions(depends_on=[group]),
            )

        members = group_conf.get("users") or []
        missing_members = [user for user in members if user not in users]
        if missing_members:
            pulumi.log.warn(
                "IAM group '%s' references users not defined in configuration: %s"
                % (name, ", ".join(missing_members))
            )
        valid_members = [user for user in members if user in users]
        if valid_members:
            aws.iam.GroupMembership(
                f"{name}-membership",
                group=group.name,
                users=[users[user].name for user in valid_members],
                opts=pulumi.ResourceOptions(depends_on=[group] + [users[user] for user in valid_members]),
            )

    pulumi.export("iam_users", {name: user.name for name, user in users.items()})
    pulumi.export("iam_groups", {name: group.name for name, group in groups.items()})

    return {"users": users, "groups": groups}
