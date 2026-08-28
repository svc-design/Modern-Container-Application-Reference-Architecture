# XConnect-One 实施更新记录

状态日期：2026-08-28  
当前状态：按用户要求暂停新增编码，保留可恢复工作现场  
长期集成分支：`codex/xconnect-overlay-productization`

## 1. 已冻结的产品决策

- 产品系列名称为 XConnect-One，与 XConnect-APP 互补并共用客户端能力。
- CLI 二进制和用户命令统一为 `xconnect`；`overlayctl` 不作为产品发布名。
- 第一版只支持 Xray-core 或 libXray，不提供 sing-box 运行时或回退。
- 默认网络模型为 L3；L2 仅作为后续受控 Linux Gateway 能力。
- macOS/iOS 只通过 `NEPacketTunnelProvider` 管理隧道；macOS 不使用 sudo
  脚本直接修改系统路由。
- Accounts 是设备、地址、策略、节点和投影的唯一事实来源。
- 动态 ACL 默认拒绝；Gateway 是权威执行点，客户端策略属于本地防御和解释能力。
- 静态 `group_vars` 客户端清单只有在 shadow、apply、运行时读回和连续健康证据
  全部通过后才能退役。
- 所有批次在隔离 worktree 和 `codex/xconnect-*` 特性分支开发，不覆盖原工作区改动。

## 2. 已完成并推送的批次

### IAC / `iac_modules`

| 批次 | 分支 | 最终 SHA | 主要内容 |
|---|---|---|---|
| 文档 | `codex/xconnect-productization-docs` | `822b660` | 产品化开发计划和项目模板 |
| 01 | `codex/xconnect-batch-01-contracts` | `944354c` | 产品、运行时和基础合同 |
| 02 | `codex/xconnect-batch-02-signing-vectors` | `6476ea1` | SignedConfig/Gateway 签名向量 |
| 03 | `codex/xconnect-batch-03-control-plane-contracts` | `83f0b58` | HTTP、注册和 Gateway 控制面合同 |
| 04 | `codex/xconnect-batch-04-acl-runtime-contracts` | `f123c0f` | 动态 ACL canonical artifact 合同 |
| 05 | `codex/xconnect-batch-05-lifecycle-apply-contracts` | `b531cf5` | 设备生命周期、reconcile、apply 状态机 |
| 06 | `codex/xconnect-batch-06-device-session-contracts` | `4817336` | `xdc_` 长期设备凭证、轮换、session/revoke、签名密钥环和规范 rotation vector 合同 |
| 07 | `codex/xconnect-batch-07-signed-policy-contracts` | `0a6afab` | SignedConfig v2 策略引用、内容协商和设备 session key-ring 合同 |

### Accounts 控制面

| 批次 | 分支 | 最终 SHA | 主要内容 |
|---|---|---|---|
| 01 | `codex/xconnect-batch-01-overlay-contracts` | `01b8093` | Overlay API 基础合同 |
| 02 | `codex/xconnect-batch-02-signed-config-projection` | `449e5f0` | 签名客户端配置投影 |
| 03 | `codex/xconnect-batch-03-projection-persistence` | `f68344e` | 投影持久化和幂等性 |
| 04 | `codex/xconnect-batch-04-invite-enrollment` | `6056a98` | 一次性邀请和设备注册 |
| 05 | `codex/xconnect-batch-05-gateway-projection` | `5c4a6ed` | GatewaySnapshot 投影 |
| 06 | `codex/xconnect-batch-06-acl-compiler` | `30c288e` | 确定性动态 ACL 编译器 |
| 07 | `codex/xconnect-batch-07-device-lifecycle` | `d7e2258` | 生命周期、Gateway apply、reconcile 和永久 WireGuard key tombstone |
| 08 | `codex/xconnect-batch-08-device-session` | `14a79e7` | 耐久设备凭据、短期 session、轮换、撤销、OpenAPI 和迁移 |

Batch07 的安全补丁永久保留 `(network_id, wireguard_public_key)` 历史占用，
阻止已撤销密钥、轮换旧密钥、同设备回滚和并发抢占。Memory/PostgreSQL 的
register、join、静态导入、Upsert 和 rotate 均在事务内 claim。

### XConnect-APP / Client

| 批次 | 分支 | 最终 SHA | 主要内容 |
|---|---|---|---|
| 00 | `codex/xconnect-batch-00-docs` | `ba0cc8b` | 客户端产品化文档 |
| 01 | `codex/xconnect-batch-01-product-plugin` | `f05d97c` | XConnect-One 内置产品插件 |
| 02 | `codex/xconnect-batch-02-cli-join` | `6b42f5e` | `xconnect join` 基础用例 |
| 03 | `codex/xconnect-batch-03-desktop-runtime` | `1258af6` | 桌面运行时边界 |
| 04A | `codex/xconnect-batch-04-signed-config-client` | `59bba5d` | SignedConfig 验签和 replay floor |
| 04B | `codex/xconnect-batch-04-invite-join` | `02fd25a` | 一次性邀请 Join |
| 05 | `codex/xconnect-batch-05-mobile-enrollment` | `3b899bc` | 移动端注册和受保护宿主边界 |
| 06 | `codex/xconnect-batch-06-cli-lifecycle-policy` | `f762fd3` | CLI 生命周期、邀请、policy consumer、崩溃恢复 |
| 07 | `codex/xconnect-batch-07-device-session` | `7718ad3` | 受保护设备凭据、session sync、轮换/leave 恢复与五平台存储边界 |

Batch06 的普通 `leave` 在长期设备凭证未落地前保持 fail-closed，不会把本地清理
误报成远端撤销。`leave --local-only` 是显式恢复操作。

### Playbooks / Gateway

| 批次 | 分支 | 最终 SHA | 主要内容 |
|---|---|---|---|
| 01 | `codex/xconnect-batch-01-gateway-contract` | `41bcb7c` | Gateway 角色合同 |
| 02 | `codex/xconnect-batch-02-gateway-shadow` | `3491e3e` | shadow 投影和差异 |
| 03 | `codex/xconnect-batch-03-gateway-agent-shadow` | `2c97306` | Gateway Agent shadow |
| 04 | `codex/xconnect-batch-04-static-import-shadow` | `c5bab23` | 静态清单导入和 shadow 对照 |
| 05 | `codex/xconnect-batch-05-gateway-apply` | `e7d2c7d` | 事务 apply、LKG、回滚、旧服务安全接管 |
| 06 | `codex/xconnect-batch-06-rollout-gates` | `98c45b2` | accounts-only 签名切换授权、readiness 门禁和 shadow 回退 |

Batch05 已覆盖旧 `wg-xwm`/`xray-wg-tproxy` 状态捕获、端口接管、失败恢复、
受保护的 WireGuard/relay/TLS 文件注入、专用用户预检和三阶段失败注入。

## 3. 本轮收口状态

此前暂停的 Accounts Batch08、Client Batch07 和 Gateway Batch06 已完成、推送并核对
远端 SHA；三个 worktree 均干净，未创建 PR，未修改静态 `group_vars`。它们是可审查
候选，不是 production rollout 许可。

## 4. 已通过的主要验证

- IAC Batch06：20 个合同测试通过；Batch07：22 个合同测试通过。
- Accounts Batch08：除依赖本机 `wg` 的既有 overlayctl E2E 外，全仓 Go 测试通过；
  `go test -race ./internal/store ./api`、`go vet ./...`、OpenAPI/YAML/JSON 和合同测试通过。
  PostgreSQL 覆盖为 sqlmock 事务/锁/回放与迁移结构验证，未声称真实数据库烟测。
- Client Batch07：相关 Go test/race/vet、Flutter analyze、152 个 Flutter 测试、
  XConnect-One runtime gate、Linux/macOS/Windows CLI 编译和 Android/iOS credential package build 通过。
  仓库根全量 Go 测试依赖缺失的 sibling `libXray` checkout。
- Gateway Batch06：Go test/race/vet、fuzz smoke、签名/篡改门禁、角色/Agent/脚本、
  六套 Ansible 测试、ansible-lint、schema/workflow parse 及 Linux amd64/arm64 构建通过。

## 5. 尚未声明完成的能力

- 尚无真实 Accounts + Gateway + 五平台客户端的 live E2E 证据。
- SignedConfig v2 目前只有 IAC 合同，Accounts producer 和 Client consumer 尚未实现。
- Gateway 的 accounts-only readiness consumer 已实现，但 Accounts 尚未签发对应的
  Controller-signed authorization producer/endpoint；这阻断 production cutover。
- macOS/iOS、Windows、Android、Linux 的真实发布构建、签名、安装、升级和故障恢复
  尚未形成统一发布证据。
- 静态 `group_vars` 客户端列表没有删除，也不应在门禁完成前删除。
- 本轮没有创建新的 batch PR；恢复后需核对远端 PR 状态，并在实际创建前取得用户确认。

## 6. 恢复入口

继续编码时按 `XCONNECT_ONE_TODO.md` 的 P0 顺序实施；先核对远端特性分支、合同版本和
生产阻断项，不要从原始脏工作区重新开始，也不要覆盖用户已有改动。
