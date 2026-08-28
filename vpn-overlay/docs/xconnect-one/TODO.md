# XConnect-One 跨仓 TODO

状态日期：2026-08-28

原则：先补齐生产阻断与真实证据，再讨论静态清单退役或 main 合并。

## P0：Accounts 生产阻断

- [ ] 在临时真实 PostgreSQL 上执行 Batch 07/08 migration、并发 credential claim、
  rotation 丢响应恢复、撤销 receipt 重放与回滚烟测。
- [x] Accounts Batch 09 已实现 Controller-signed cutover authorization producer，签名
  严格绑定 Gateway canonical fields，并对 signer/store/snapshot、成功 apply、import
  baseline 和 pending reconcile 缺口 fail-closed（远端 `98edbbe`）。
- [ ] 使用根保护公钥完成 Accounts producer → Gateway verifier 的篡改、过期、重放、
  错误网络/节点和 key rotation 的 staging live 联调与连续 soak；未通过前禁止
  production accounts-only。
- [ ] 实现 SignedConfig v2 producer：仅在显式 Accept 下返回 v2，默认保持严格 v1；
  两者都设置 `Vary: Accept` 和 `private, no-store`。
- [ ] 实现同源 policy artifact endpoint，并把 generation/digest/path/media type 纳入
  Ed25519 签名；用 IAC 向量与已完成的 Client Batch 08 consumer 做 live 联调。

## P1：五平台真实运行时

- [ ] macOS：接入 PacketTunnelProvider + libXray、App Group/Keychain 和 crash recovery；
  不使用 sudo 或直接系统路由脚本。
- [ ] iOS：完成 protected host bridge、后台恢复、entitlement、签名和真机数据面测试。
- [ ] Android：完成 VpnService/JNI/libXray、Keystore、前台服务、进程重建及
  always-on/lockdown 测试。
- [ ] Windows：完成受控 Service/Wintun/libXray、Credential Manager/DPAPI、
  非管理员 UI、升级和回滚。
- [ ] Linux：完成 Xray/WireGuard owned runtime、最小权限 helper、systemd 生命周期、
  secret 权限和发行版矩阵。
- [ ] 所有平台在能力不足时 fail-closed；只声明 Xray-core/libXray，不提供 sing-box。

## P1：Gateway staging 与静态清单退役门禁

- [ ] 建立 Accounts + Gateway staging，连续保存 import receipt、shadow diff、签名授权、
  snapshot/policy digest、apply-result、runtime readback 和健康样本。
- [ ] 演练控制面不可用、错误签名、过期授权、runtime fault、quarantine、LKG 和显式
  shadow 回退，不自动恢复已撤销或轮换前 key。
- [ ] 完成 accounts-only soak 后冻结静态清单写入；确认终端 Join/Leave 不触发 Ansible
  重跑，且动态 peer 只来自 Accounts。
- [ ] 取得可恢复备份、回滚证据和明确审批后，才提交删除静态客户端列表的独立变更。
  当前 `group_vars` 必须保留。

## P2：跨仓 E2E、发布和文档

- [ ] 覆盖 join、sync、ACL allow/deny、rotate、suspend、revoke、leave、重放、控制面
  中断、证书轮换、升级/降级和 Gateway rollback 的真实租户 E2E。
- [ ] 为五平台保存版本、generation、digest、默认拒绝、数据面连通和 LKG 证据。
- [ ] 完成 CLI/APP/Gateway 兼容矩阵、SBOM、制品签名、安装/升级、管理员手册、用户
  Join 指南、监控告警和故障恢复文档。

## PR 与集成

- [ ] 核对四仓远端长期分支和已有 PR，避免重复创建。
- [ ] 每个 PR 附合同版本、依赖 SHA、测试证据、迁移/回滚和未覆盖限制，base 使用
  `codex/xconnect-overlay-productization`。
- [ ] 当前没有新 PR；创建 PR 是外部变更，执行前需再次取得用户确认。
