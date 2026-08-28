# XConnect Overlay 项目模板

这些模板配套 `../PRODUCTIZATION_DEVELOPMENT_PLAN.md` 使用。

| 文件 | 用途 |
|---|---|
| `ADR.md` | 记录架构决策及其安全、发布和回滚影响 |
| `EPIC.md` | 建立跨仓库、跨平台开发 Epic |
| `FEATURE.md` | 定义可独立验收的功能任务 |
| `BUG.md` | 报告带 runtime/config generation 的缺陷 |
| `TEST_CASE.md` | 建立可自动化、可收集证据的测试 Case |
| `PULL_REQUEST_TEMPLATE.md` | Overlay 相关 PR 的统一门禁 |

复制模板后应删除不适用的提示文字，但不得省略安全影响、测试、发布和回滚部分。

涉及 XConnect-One 控制面契约时，`TEST_CASE.md` 必须记录 producer/consumer
commit、schema/vector、HTTP auth/cache 边界和脱敏 fixture 类型；PR checklist
必须证明 SignedConfig/GatewaySnapshot 向量无漂移、静态导入 hash 幂等且未引入
sing-box runtime。IAC 契约 PR 不得顺带修改 Terraform resource。
