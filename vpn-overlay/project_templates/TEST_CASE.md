# CASE-ID：标题

- Level: unit | contract | integration | e2e | platform | security | soak
- Priority: P0 | P1 | P2
- Platforms: linux | macos | windows | ios | android | gateway | control-plane
- Automated: yes | partial | no
- Release gate: required | optional
- Owner:

## Requirement

链接到 Epic、Feature、ADR、API 或安全要求。

## Preconditions

-

## Fixture / topology

```text
client-a → gateway-a ⇄ gateway-b → service-b
```

## Input

- Client version:
- Gateway version:
- Config generation:
- Policy revision:
- Fault profile:

## Steps

1.

## Expected result

- 控制面：
- 客户端：
- Gateway：
- 数据面：
- 审计/指标：

## Required evidence

- [ ] Commands and exit codes
- [ ] Redacted configs/snapshots
- [ ] Runtime status
- [ ] Relevant metrics/logs
- [ ] Connectivity allow/deny result
- [ ] Cleanup result

## Cleanup

1.

## Automation command

```bash
# command
```

## Pass/fail rule

写出机器可判断的规则，不能只写“看起来可以”。
