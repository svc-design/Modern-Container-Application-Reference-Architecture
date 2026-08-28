## Outcome


## Scope


## Architecture/API changes

- Related ADR:
- OpenAPI/schema:
- Database migration:
- Client/Gateway compatibility:
- Producer source and commit:
- Consumer mirror and contract version:

## Security review

- [ ] 不记录或提交私钥、token、密码、VLESS credential
- [ ] 鉴权和授权边界已测试
- [ ] ACL 不能仅依赖客户端执行
- [ ] 配置签名、generation 和 rollback 行为已覆盖
- [ ] 审计事件已覆盖敏感变更
- [ ] 正常 fixture/vector 不含 raw join/enrollment/node token
- [ ] HTTP 边界明确 HTTPS、auth、Content-Type、Cache-Control
- [ ] one-time/replay/idempotency 语义已覆盖
- [ ] Xray-only；未增加 sing-box runtime/fallback
- [ ] Gateway shadow 契约保持 `applied_generation=0`、`runtime_applied=false`

## Verification

- Unit:
- Contract:
- Cross-repo vector SHA-256:
- Valid/invalid/redaction fixture coverage:
- Integration/E2E:
- Platform:
- Fault injection/soak:
- Evidence:

## Observability

- [ ] Metrics added/updated
- [ ] Structured logs use correlation ID and are redacted
- [ ] Diagnostics updated
- [ ] Alert/SLO impact documented

## Rollout / rollback

- Feature flag:
- Rollout stages:
- Rollback command/trigger:
- Last-known-good behavior:

## Documentation

- [ ] User guide
- [ ] Developer/architecture docs
- [ ] Operations runbook
- [ ] API/generated docs
- [ ] Changelog

## Final checklist

- [ ] Generated clients and golden files have no uncommitted diff
- [ ] Existing WireGuard-over-VLESS closure still passes
- [ ] Static/dynamic projection diff checked when relevant
- [ ] Cross-platform behavior or exclusions explicitly listed
- [ ] JSON Schema 为 Draft 2020-12 且 `additionalProperties: false`
- [ ] unknown field、duplicate member、trailing JSON 均有失败测试
- [ ] Accounts/IAC/XConnect-APP SignedConfig vector 无漂移
- [ ] GatewaySnapshot vector 与 Playbooks Agent golden byte-for-byte 一致
- [ ] 静态导入 canonical body hash 与 Idempotency-Key 一致
- [ ] 未改 Terraform resource，未执行网络写或部署（仅契约 PR 时）
