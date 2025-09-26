# 阿里云最小化 Landing Zone（MVP 单账号版）规划

## 1. 设计目标
- 面向个人/学习场景，优先使用免费或基础版服务，控制成本。
- 满足身份安全、操作留痕、安全基线、网络隔离、费用管控与自动化等基础能力。
- 采用 Pulumi（Python）与 GitHub Actions 自动化 IaC 流程，便于后续扩展到多账号/组织。

## 2. 总体架构概览
```
┌────────────────────────────────────────────────────────────┐
│ 阿里云主账号（个人）                                       │
│  ├─ 身份安全：RAM 用户 + MFA                               │
│  ├─ 日志审计：ActionTrail -> OSS（IA 级别）                │
│  ├─ 配置合规：Cloud Config 基础规则                        │
│  ├─ 安全检测：云安全中心（基础版）                         │
│  ├─ 网络：1 个 VPC，Prod/Test 各 1 个专有网络交换机        │
│  ├─ IaC：Pulumi Python 项目 + OSS Backend（可选）          │
│  └─ DevOps：GitHub Actions + Pulumi Automation API         │
└────────────────────────────────────────────────────────────┘
```

## 3. 身份与访问控制
- **主账号安全**
  - 启用多因素认证（MFA），绑定虚拟 MFA 设备。
  - 为 IaC 运维创建专用 RAM 用户 `ops-automation`，授予最小权限策略（如 `AliyunOSSFullAccess`、`AliyunVPCFullAccess`、`AliyunConfigFullAccess` 等），并强制 MFA。
  - 创建只读监控 RAM 用户 `audit-viewer`，授予只读策略（`ReadOnlyAccess`）以便审计。
- **访问密钥管理**
  - GitHub Actions 使用 `ops-automation` 的访问密钥，通过 GitHub Secrets 管理。
  - 对个人 CLI 使用临时安全令牌（STS）或 RAM 用户专用访问密钥，周期性轮换。

## 4. 操作留痕与日志归档
- 开启 **ActionTrail**（跟踪所有全局事件），日志投递到同区域 OSS Bucket。
  - Bucket 命名建议：`lz-mvp-actiontrail-logs`，开启版本控制与生命周期（180 天转低频、365 天归档）。
  - 为 GitHub Actions 拉取状态文件时也可共享该 OSS 作为 Pulumi backend（可选）。
- 针对 VPC 网络流量，可择机启用 **流日志**（需按量计费，学习场景可在需要时手动开启）。

## 5. 安全基线
- **Cloud Config**：启用基础合规包（免费），包含身份、网络、存储公共规则。
- **云安全中心**：启用基础版（免费），获取基础漏洞、病毒、基线检测告警。
- **行为审计**：ActionTrail 日志结合 Security Center 事件统一归档。

## 6. 网络隔离与资源命名
- 创建单个 VPC（CIDR 例：`10.10.0.0/16`）。
- 创建两个交换机（子网）：
  - `lz-prod-subnet`：`10.10.1.0/24`
  - `lz-test-subnet`：`10.10.2.0/24`
- 创建默认安全组 `lz-base-sg`，默认仅放行出站、限制入站，按需为 Prod/Test 单独创建更精细安全组。
- 预留弹性公网 IP/SLB 暂不创建，按实验需要手动启用。

## 7. 费用与资源标记
- 所有资源统一添加标签：
  - `env=prod|test`
  - `project=landingzone-mvp`
  - `owner=<GitHub handle>`
- 在费用中心创建预算告警（按需启用）。个人学习场景可设置总预算 10-20 USD/月，告警方式为邮件/短信。
- 使用资源目录命名规范，便于后续扩展：`lz-<env>-<service>-<purpose>`。

## 8. 基础自动化实现路线（Pulumi + Python）
### 8.1 代码结构建议
```
landingzone/
 ├─ Pulumi.yaml                     # 项目信息（名称、运行时 python）
 ├─ Pulumi.<stack>.yaml             # Stack 配置（region、RAM 用户、标签）
 ├─ __main__.py                     # 主入口，定义资源
 ├─ config/__init__.py              # 配置解析与常量
 ├─ modules/                        # 可选资源模块化
 └─ requirements.txt                # Pulumi 依赖（pulumi>=3, pulumi-alicloud）
```

### 8.2 核心资源清单
| 资源 | Pulumi 资源类型 | 关键配置 | 备注 |
| ---- | ---------------- | -------- | ---- |
| RAM 用户 `ops-automation` | `alicloud.ram.User` | login_profile，MFA enforced | 初始需手工绑定 MFA |
| RAM 用户 `audit-viewer` | `alicloud.ram.User` | password reset required | |
| RAM 用户组与策略 | `alicloud.ram.Group`, `alicloud.ram.Attachment` | 最小权限 | |
| OSS Bucket | `alicloud.oss.Bucket`, `BucketLogging` | versioning/lifecycle | ActionTrail + Pulumi backend |
| ActionTrail | `alicloud.actiontrail.Trail` | event RW=All, oss_bucket_name | |
| Cloud Config 合规包 | `alicloud.config.ConfigurationRecorder` + `DeliveryChannel` + `Rule` | 启动基础规则 | 免费 |
| VPC 与交换机 | `alicloud.vpc.Network`, `alicloud.vpc.Switch` | CIDR, tags | |
| 安全组 | `alicloud.ecs.SecurityGroup` | 默认拒绝入站 | |

> 说明：RAM 用户及 MFA 部分需结合控制台操作完成绑定。Pulumi 负责用户与策略创建。

### 8.3 Pulumi 后端与状态存储
- 初始可使用 Pulumi Service（免费层）管理状态。
- 若需完全自管，配置 Pulumi Backend 指向 OSS（例如 `pulumi login oss://lz-mvp-actiontrail-logs/pulumi-state`）。

## 9. GitHub Actions 流水线
### 9.1 Secrets 管理
- `ALICLOUD_ACCESS_KEY_ID`、`ALICLOUD_ACCESS_KEY_SECRET`：`ops-automation` RAM 用户密钥。
- `PULUMI_ACCESS_TOKEN`：使用 Pulumi Service 时需要。

### 9.2 Workflow 示例
```
name: Deploy Landing Zone

on:
  push:
    paths:
      - "landingzone/**"
  workflow_dispatch:

jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pulumi/actions@v4
        with:
          command: preview
          stack-name: personal/dev
        env:
          ALICLOUD_ACCESS_KEY_ID: ${{ secrets.ALICLOUD_ACCESS_KEY_ID }}
          ALICLOUD_ACCESS_KEY_SECRET: ${{ secrets.ALICLOUD_ACCESS_KEY_SECRET }}
          PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
  up:
    needs: preview
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: pulumi/actions@v4
        with:
          command: up
          stack-name: personal/prod
          work-dir: landingzone
        env:
          ALICLOUD_ACCESS_KEY_ID: ${{ secrets.ALICLOUD_ACCESS_KEY_ID }}
          ALICLOUD_ACCESS_KEY_SECRET: ${{ secrets.ALICLOUD_ACCESS_KEY_SECRET }}
          PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
```

### 9.3 扩展建议
- 引入 `pulumi/actions` 的 `refresh` 步骤周期对齐实际资源。
- 加入 `pulumi destroy` 手动触发 workflow 以清理环境。
- 将 Stack 配置拆分为 `personal/dev`（测试）与 `personal/prod`（实际），通过 Pulumi config 存储 region、标签等。

## 10. 运维与监控
- 配置 CloudMonitor 告警联系人（免费），监控 ActionTrail 投递失败、OSS 存储量、预算告警等。
- 使用 Open-Source 方案（如 Loki/Grafana）处理导出的日志，可部署在 Test 子网内。
- 定期通过 Pulumi `pulumi stack outputs` 导出关键信息，并存档到 Git 仓库的环境文档中。

## 11. 后续扩展路线
1. **多账号/组织**：接入阿里云资源目录（Resource Directory），创建成员账号，将基础设施逐步下放。
2. **网络增强**：引入专有网络连接（如 VPN Gateway、CEN）实现混合云；Prod/Test 细分更多子网。
3. **安全加固**：升级云安全中心专业版，接入访问控制（RAM Policy）细化到资源级；启用日志审计高级特性。
4. **CI/CD 集成**：结合 GitHub Environments + Pulumi Stack References，实现多环境审批与依赖管理。
5. **成本优化**：自动化导出账单到 OSS + QuickSight/QuickBI 分析，结合 Function Compute 周期性扫描闲置资源。

---
本规划覆盖单账号最小可行阿里云 Landing Zone，满足基本安全、合规、成本与自动化需求，并预留多账号、网络与安全扩展空间。
