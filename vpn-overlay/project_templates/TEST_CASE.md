# CASE-ID：标题

- Level: unit | contract | integration | e2e | platform | security | soak
- Priority: P0 | P1 | P2
- Platforms: linux | macos | windows | ios | android | gateway | control-plane
- Automated: yes | partial | no
- Release gate: required | optional
- Owner:
- Producer repository/commit:
- Consumer repository/commit:
- Contract schema/vector:

## Requirement

链接到 Epic、Feature、ADR、API 或安全要求。

## Preconditions

-

## Fixture / topology

```text
client-a → gateway-a ⇄ gateway-b → service-b
```

Fixture class: valid | invalid | redaction-only | interoperability-vector

## Input

- Client version:
- Gateway version:
- Config generation:
- Policy revision:
- Fault profile:
- HTTP method/path/auth/media type/cache policy:
- Idempotency key/body SHA-256:

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
- [ ] Exact request/response bytes or vector SHA-256 (redacted)
- [ ] Unknown-field, duplicate-member, and trailing-JSON rejection
- [ ] `Cache-Control`/HTTPS/auth boundary evidence when applicable
- [ ] One-time/replay/idempotency evidence when applicable
- [ ] Xray-only and Gateway shadow-only guard evidence

## Cleanup

1.

## Automation command

```bash
# command
```

## Pass/fail rule

写出机器可判断的规则，不能只写“看起来可以”。

## Secret fixture rule

- 正常 golden 只使用 `<redacted>`/`REDACTED_*` 占位符。
- raw token-shaped 测试值只能进入明确的 invalid/redaction fixture。
- 不得从本地、CI、Vault、控制面或真实设备复制 secret 到 evidence。
