from __future__ import annotations


from typing import Dict, Iterable, Mapping, Optional

import pulumi
import pulumi_alicloud as alicloud


PolicyConfig = Mapping[str, str]
UserConfig = Mapping[str, object]
GroupConfig = Mapping[str, object]


def _normalize_policies(policies: Optional[Iterable[PolicyConfig]]) -> Iterable[PolicyConfig]:
    return policies or []


def create_ram_identity(
    identity_conf: Mapping[str, object],
) -> Dict[str, Dict[str, pulumi.Resource]]:
    """Create RAM users, groups, and policy attachments based on configuration."""
    users_conf = identity_conf.get("users", []) or []
    groups_conf = identity_conf.get("groups", []) or []

    users: Dict[str, pulumi.Resource] = {}
    groups: Dict[str, pulumi.Resource] = {}

    for user_conf in users_conf:
        name = user_conf["name"]
        args = {
            "name": name,
            "display_name": user_conf.get("display_name"),
            "email": user_conf.get("email"),
            "mobile": user_conf.get("mobile"),
            "comments": user_conf.get("comments"),
            "force": user_conf.get("force_destroy"),
        }
        args = {k: v for k, v in args.items() if v is not None}
        user = alicloud.ram.User(name, **args)
        users[name] = user

        for index, policy in enumerate(_normalize_policies(user_conf.get("policies"))):
            alicloud.ram.UserPolicyAttachment(
                f"{name}-policy-{index}",
                policy_name=policy["name"],
                policy_type=policy.get("type", "System"),
                user_name=name,
                opts=pulumi.ResourceOptions(depends_on=[user]),
            )

    for group_conf in groups_conf:
        name = group_conf["name"]
        args = {
            "group_name": name,
            "comments": group_conf.get("comments"),
            "force": group_conf.get("force_destroy"),
        }
        args = {k: v for k, v in args.items() if v is not None}
        group = alicloud.ram.Group(name, **args)
        groups[name] = group

        for index, policy in enumerate(_normalize_policies(group_conf.get("policies"))):
            alicloud.ram.GroupPolicyAttachment(
                f"{name}-policy-{index}",
                group_name=name,
                policy_name=policy["name"],
                policy_type=policy.get("type", "System"),
                opts=pulumi.ResourceOptions(depends_on=[group]),
            )

        members = group_conf.get("users") or []
        missing_members = [user for user in members if user not in users]
        if missing_members:
            pulumi.log.warn(
                f"RAM group '{name}' references users not defined in configuration: {', '.join(missing_members)}"
            )
        if members:
            alicloud.ram.GroupMembership(
                f"{name}-membership",
                group_name=name,
                user_names=[user for user in members if user in users],
                opts=pulumi.ResourceOptions(depends_on=[group] + [users[user] for user in members if user in users]),
            )

    pulumi.export("ram_users", {name: user.name for name, user in users.items()})
    pulumi.export("ram_groups", {name: group.group_name for name, group in groups.items()})

    return {"users": users, "groups": groups}
