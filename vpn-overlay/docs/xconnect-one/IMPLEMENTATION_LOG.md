# XConnect-One 跨仓实施更新记录

状态日期：2026-08-28  
长期集成分支：`codex/xconnect-overlay-productization`  
记录范围：合同、Accounts 控制面、XConnect-APP/CLI、Playbooks Gateway

## 产品与安全基线

- 产品名为 XConnect-One，与 XConnect-APP 共享客户端和插件能力；发布 CLI 为
  `xconnect`。
- v1 只支持 Xray-core 或 libXray。`sing-box` 不是运行时、备用路径或自动回退。
- 默认提供 L3 Overlay；L2 只作为后续受控 Linux Gateway 能力。
- Accounts 是设备、地址、节点、ACL 和投影的事实来源；Gateway 是动态 ACL 的权威
  执行点，默认拒绝。
- macOS/iOS 数据面必须进入 `NEPacketTunnelProvider`；macOS 客户端不通过 sudo
  脚本直接修改系统路由。
- 静态 `group_vars` 客户端清单仍保留。只有 shadow、apply、运行时读回、连续健康和
  回滚演练形成证据后，才允许进入退役审批。

## 远端批次索引

下表中的 SHA 是已推送特性分支的已知提交，不表示已合并到长期分支或 main。

| 仓库 | 已完成批次 | 远端分支 / SHA | 可审查结果 |
|---|---|---|---|
| `iac_modules` | Batch 07 | `codex/xconnect-batch-07-signed-policy-contracts` / `950e32f` | SignedConfig v2、耐久设备凭据、session key ring 和跨仓合同向量 |
| Accounts | Batch 08 | `codex/xconnect-batch-08-device-session` / `14a79e7` | 一次性 Join 后的耐久设备凭据、短期 session、轮换、撤销、迁移和 API |
| Accounts | Batch 09 | `codex/xconnect-batch-09-cutover-authorization` / `98edbbe` | 内部服务鉴权的独立 Ed25519 cutover authorization producer 与 fail-closed 门禁 |
| XConnect-APP | Batch 07 | `codex/xconnect-batch-07-device-session` / `7718ad3` | `xconnect sync/credential rotate/leave`、受保护存储和恢复状态机 |
| XConnect-APP | Batch 08 | `codex/xconnect-batch-08-signed-config-v2` / `18d328e` | 显式 v2 consumer、严格 v1 默认、同源 policy 校验和原子 apply/readback/ACK |
| Playbooks | Batch 06 | `codex/xconnect-batch-06-rollout-gates` / `98c45b2` | 签名 accounts-only 授权验证、readiness 门禁和安全 shadow 回退 |

### `iac_modules` 合同演进

| 批次 | 远端 SHA | 内容 |
|---|---|---|
| 产品化文档 | `822b660` | 产品计划、仓库模板和测试设计 |
| 01 | `944354c` | 产品、运行时和基础合同 |
| 02 | `6476ea1` | SignedConfig/Gateway Ed25519 向量 |
| 03 | `83f0b58` | HTTP、注册和 Gateway 控制面合同 |
| 04 | `f123c0f` | 动态 ACL canonical artifact 合同 |
| 05 | `b531cf5` | 设备生命周期、reconcile 和 apply 状态机 |
| 06 | `4817336` | `xdc_` 设备凭据、session/revoke、轮换向量和 signing key ring |
| 07 | `950e32f` | SignedConfig v2 policy 引用和内容协商合同 |

### Accounts 控制面演进

Batch 01-09 的远端 SHA 依次为 `01b8093`、`449e5f0`、`f68344e`、
`6056a98`、`5c4a6ed`、`30c288e`、`d7e2258`、`14a79e7`、`98edbbe`。已经覆盖基础
Overlay API、签名投影、持久化、邀请 Join、Gateway 投影、动态 ACL 编译、设备生命周期
以及耐久设备 session。Batch 07 的永久 WireGuard key tombstone 阻止撤销、轮换旧 key
和并发重用。Batch 09 只有在 signer/store/snapshot、成功 apply、import baseline 和干净
reconcile 状态同时存在时才签发与 Gateway Batch 06 canonical fields 严格一致的授权。

### XConnect-APP/CLI 演进

Batch 00-08 的远端 SHA 为 `ba0cc8b`、`f05d97c`、`6b42f5e`、`1258af6`、
`59bba5d`/`02fd25a`、`3b899bc`、`f762fd3`、`7718ad3`、`18d328e`。
当前已形成产品插件、`xconnect join`、桌面运行时边界、SignedConfig 验签、邀请 Join、
移动端受保护宿主边界、CLI 生命周期、耐久设备 session 和 SignedConfig v2 consumer。

### Playbooks/Gateway 演进

Batch 01-06 的远端 SHA 为 `41bcb7c`、`3491e3e`、`2c97306`、`c5bab23`、
`e7d2c7d`、`98c45b2`。当前已形成角色合同、shadow、静态导入/差异、事务 apply、
LKG/回滚、旧服务安全接管和 accounts-only readiness。动态 peer 在 accounts-only 模式
只接受 Accounts 投影，但生产切换仍被控制面签名授权 producer 阻断。

## 验证记录

- IAC Batch 06/07 合同套件分别通过 20/22 项验证，包括 schema、strict JSON、
  canonical digest、Ed25519 向量、窗口和重放约束。
- Accounts Batch 08 通过目标 Go tests、race、vet、OpenAPI/YAML/JSON、迁移结构和跨仓
  合同测试；PostgreSQL 行为当前主要由 sqlmock 覆盖，尚无真实 PostgreSQL 烟测证据。
- Accounts Batch 09 通过签名 golden、HTTP fail-closed、OpenAPI/schema/migration index、
  audit、race/vet/parse 门禁；全量测试只剩依赖本机 `wg` 的既有 overlayctl E2E 失败。
- Client Batch 07 通过目标 Go test/race/vet、Flutter analyze、152 个 Flutter 测试、
  runtime gate 和多目标编译。Batch 08 的 v2 consumer 通过目标 test/race 和跨平台编译。
  仓库根全量 Go 门禁仍依赖未检出的 sibling `libXray`。
- Gateway Batch 06 通过 Go test/race/vet、fuzz smoke、签名/篡改门禁、角色和脚本验证、
  Ansible 测试/lint、schema/workflow parse 以及 Linux amd64/arm64 构建；namespace 测试
  在 Ubuntu CI 执行，在 macOS 安全跳过。

这些结果是自动化合同与集成门禁，不是已部署的 Accounts + Gateway + 五平台 live E2E。

## 当前限制与发布状态

- Accounts 已完成 Controller-signed cutover authorization producer 的代码批次，但尚未
  完成 staging 部署、根保护公钥/私钥运维、Gateway live 验证和连续 soak；因此仍不能
  声明 production accounts-only。Accounts 尚未生产 SignedConfig v2 representation/
  policy artifact，客户端 v2 live 联调也未完成。
- macOS、Windows、Linux、iOS、Android 的真实签名构建、安装、升级、数据面连通、
  断网恢复和故障回滚尚未汇总为发布证据。
- 静态 `group_vars` 未删除、未由 Join/Leave 反写，也不得在门禁完成前删除。
- 当前批次均保留在特性分支；截至本记录没有创建新的 PR。后续 PR 的 base 为
  `codex/xconnect-overlay-productization`，实际创建前需再次取得用户确认。
