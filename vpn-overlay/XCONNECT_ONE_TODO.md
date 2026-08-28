# XConnect-One TODO

状态日期：2026-08-28  
执行状态：暂停；以下项目未授权自动继续

## P0：恢复和长期设备凭证闭环

- [ ] 逐一检查三个暂停 worktree 的 diff，确认没有并发残留进程或未完成生成物。
- [ ] Accounts Batch08 完成 device credential PostgreSQL + Memory 实现：
  - [ ] Join 原子签发一次 `xdc_<32hex>.<43 base64url>`，只返回一次原文。
  - [ ] 数据库存 SHA-256（完整 UTF-8 token）和 tombstone，不存原文。
  - [ ] `Authorization: Device`、canonical base64url、ID binding、constant-time compare。
  - [ ] session nonce 回显、15 分钟以内 xenr、仅 config read/ACK scope。
  - [ ] 客户端生成 successor 的原子轮换和丢响应恢复。
  - [ ] device-bound revoke 幂等回执、历史 verifier 仅限终态回执路由。
  - [ ] 设备 inactive/revoked、过期、错误 scheme、错误 verifier 全部 fail-closed。
  - [ ] migration、并发、重放、日志脱敏、OpenAPI 和 HTTP cache 测试。
- [ ] Client Batch07 完成长期凭证消费：
  - [ ] Join 在 apply/ACK 前将 xdc 写入受保护存储，xenr 只存内存/短 checkpoint。
  - [ ] `xconnect sync` 执行 mint → fetch/verify → transactional apply → ACK → erase xenr。
  - [ ] `xconnect leave` 收到远端终态回执后才清理本地；local-only 不声称远端成功。
  - [ ] rotation 先持久化 pending successor，再提交摘要；丢响应时探测新旧凭证。
  - [ ] macOS Keychain、Windows Credential Manager/DPAPI、Linux 0700/0600 原子文件。
  - [ ] iOS/Android 只能通过 protected host bridge 使用 Keychain/Keystore。
  - [ ] 日志、diagnose、Flutter preferences、普通 state 文件不得出现 raw xdc/xenr。
- [ ] Accounts/Client/IAC wire vector、scope、nonce、expiry、idempotency 和错误码完全一致。
- [ ] 只有 scoped test、race、vet、Flutter tests 和跨仓库 vector gate 全绿后才提交/推送 WIP。

## P0：Gateway accounts-only 切换门禁

- [ ] 完成 Gateway Batch06 `xconnect-cutover-readiness`。
- [ ] readiness 同时验证 import receipt baseline、设备/地址/公钥集合、snapshot 签名、
  policy digest、controller apply 授权、observed=applied、runtime readback equal。
- [ ] 连续健康样本达到配置阈值，且没有 pending reconcile/runtime fault/quarantine。
- [ ] 任一证据缺失均拒绝 accounts-only；默认保持 shadow。
- [ ] accounts-only 后动态 peer 只来自 Accounts 投影，角色不再从 group_vars 渲染 peer。
- [ ] 保留显式回 shadow/LKG 操作，但不得自动复活撤销或轮换前密钥。
- [ ] 完成 mock HTTPS 控制面、签名 snapshot/policy、apply-result 和 Linux namespace CI。

## P1：SignedConfig v2 和客户端策略

- [ ] Accounts Batch09 实现显式
  `Accept: application/vnd.xconnect.signed-config.v2+json`；无 Accept 仍返回严格 v1。
- [ ] V1/V2 都返回 `Vary: Accept` 和 `private, no-store`，不做静默降级。
- [ ] Accounts 将 policy generation/digest/同源相对 path 纳入 Ed25519 签名并通过 v2 vector。
- [ ] enrollment policy artifact endpoint 只接受 config-read 短 token，返回 canonical artifact。
- [ ] Client Batch08 验证 SignedConfig 后才构造 policy reference；拒绝绝对 URL、跨源 redirect、
  media-type 不符、digest 不符、低 generation 和同 generation 不同 digest。
- [ ] Config 与 policy 同一事务 staging/apply/readback；失败保留 LKG 和 replay floor。
- [ ] `xconnect policy explain` 只输出设备 ID/规则结论，不泄露用户、邮箱、组或凭证。

## P1：五平台真实运行时

- [ ] macOS：把 Join/Sync/Up/Down 接入现有 PacketTunnelProvider + libXray；只用
  Network Extension/App Group/Keychain，无 sudo 和直接系统路由脚本。
- [ ] iOS：复用 PacketTunnelProvider，完成 protected credential/config bridge、后台恢复、
  entitlement 和真机测试计划。
- [ ] Android：接入现有 VpnService/JNI/libXray，完成 Keystore、前台服务、进程重建和
  always-on/lockdown 兼容测试。
- [ ] Windows：完成受控 Service/Wintun/libXray 生命周期、Credential Manager/DPAPI、
  升级回滚和非管理员 UI 边界。
- [ ] Linux：完成 Xray/WireGuard owned runtime、最小权限 helper、0700/0600 secret、
  systemd 生命周期和发行版矩阵。
- [ ] 所有平台都只声明 Xray-core/libXray；能力探测不足时 fail-closed，不伪造成功。

## P1：静态 `group_vars` 退役

- [ ] 先冻结静态清单写入，只允许迁移工具生成 canonical import。
- [ ] 保存 import receipt、shadow diff、apply/readback、连续健康和回滚演练证据。
- [ ] 在 staging 完成 accounts-only soak，再进行受控生产切换。
- [ ] 切换后确认 Ansible 不再因终端 Join/Leave 变化而重跑。
- [ ] 完成可恢复备份和明确审批后，才删除静态客户端列表；保留 schema/迁移审计记录。

## P2：E2E、发布和运维

- [ ] 建立真实测试租户：Accounts、Gateway、Linux、macOS、Windows、iOS、Android。
- [ ] 覆盖 join、sync、ACL allow/deny、key rotate、suspend、revoke、leave、Gateway rollback、
  控制面暂时不可用、token replay、升级/降级和证书轮换。
- [ ] 记录数据面连通性、默认拒绝、generation、digest、apply result 和 LKG 证据。
- [ ] 完成 CLI/APP/Gateway 版本兼容矩阵、SBOM、签名、安装包和升级文档。
- [ ] 完成安全模型、管理员手册、用户 Join 指南、故障恢复和监控告警手册。

## PR 和合并

- [ ] 恢复时先核对四个仓库的远端长期分支和已有 PR，避免重复创建。
- [ ] 每个仓库按可审查批次整理提交；PR base 为
  `codex/xconnect-overlay-productization`，最终再由长期分支进入 main。
- [ ] PR 描述附合同版本、依赖分支、测试证据、迁移/回滚和未覆盖限制。
- [ ] 创建或提交 PR 属于外部变更，实际执行前再次取得用户确认。
