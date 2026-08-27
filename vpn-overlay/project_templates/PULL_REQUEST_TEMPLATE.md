## Outcome


## Scope


## Architecture/API changes

- Related ADR:
- OpenAPI/schema:
- Database migration:
- Client/Gateway compatibility:

## Security review

- [ ] 不记录或提交私钥、token、密码、VLESS credential
- [ ] 鉴权和授权边界已测试
- [ ] ACL 不能仅依赖客户端执行
- [ ] 配置签名、generation 和 rollback 行为已覆盖
- [ ] 审计事件已覆盖敏感变更

## Verification

- Unit:
- Contract:
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
