# 阿里云 Landing Zone Baseline（单用户最小需求清单）

本文档总结了在单用户场景下构建阿里云 Landing Zone 的最小化需求。即使目前仅有一个主账号，也应提前规划，以便未来扩展到多账号治理。整体目标包括：账号治理、网络隔离、安全合规、资源管理与可扩展性。

## 1. 账号与身份基线

### 资源目录（Resource Directory）

- 启用阿里云资源目录，即便只有 1 个主账号，也能为后续多账号治理预留框架。

### 账号分层（最少 3 个账号）

- **管理账号（Management Account）**：负责开启资源目录与账单结算，不承载业务资源。
- **安全账号（Security Account）**：集中部署 Cloud Config、ActionTrail、云安全中心、日志审计等安全服务。
- **业务账号（Workload Account）**：承载 ECS、RDS、ACK 等业务资源。

### RAM 身份基线

- Root 账号必须绑定 MFA，并避免直接使用。
- 至少创建 1 个具备管理员权限的 RAM 用户，并绑定 MFA。
- 优先通过 RAM 角色 + STS 临时凭证访问，而不是长期 AccessKey。

## 2. 网络基线

### 专有网络（VPC）

- 在 Workload Account 中至少创建 1 个 VPC。
- VPC 内划分公有子网（部署 ECS 前端 / SLB 等）与私有子网（部署数据库、内部应用）。
- 配置 NAT 网关。单用户场景可使用 SNAT 共享带宽以节省费用。

### 安全组

- 默认拒绝所有入站流量，仅放通必要端口：
  - 22：限制来源 IP 访问。
  - 80/443：支持公网 Web 服务。

## 3. 安全与合规基线

### 审计与日志

- 开启 ActionTrail，记录所有 API 调用并集中存放至安全账号的 OSS 存储。
- 开启 Cloud Config，持续检测关键合规项（如未开启 MFA、资源对公网开放等）。

### 安全防护

- 启用云安全中心（基础版免费），实现漏洞、木马等基础威胁检测。

### 加密

- 在 KMS（Key Management Service）中创建 1 个自管密钥（CMK），用于加密 OSS、RDS、ECS 云盘等资源。

## 4. 资源与环境基线

### 最小计算节点

- 部署 1 台按量付费的 ECS（2 vCPU、4 GiB 内存），可作为跳板机或轻量级业务节点。
- 推荐选择 Alibaba Cloud Linux 3 或 Ubuntu LTS 公共镜像。

### 数据库

- 若需要托管数据库，可使用最低规格的 RDS MySQL 实例。

## 5. 自动化与治理基线

### 基础 IaC

- 使用 Terraform Provider for Alicloud 或 ROS（Resource Orchestration Service）管理基础资源。
- 将账号、VPC、ECS、安全策略等资源写入 IaC 模板，便于复制与审计。

### 命名规范

- 采用统一命名：`lz-<account>-<env>-<service>`。
- 示例：`lz-workload-dev-vpc1`、`lz-security-actiontrail-log`。

### 标签策略

- 制定统一标签：`owner=haitao`、`env=dev/prod`、`cost-center=personal` 等。
- 在资源目录中定义 Tag Policy，强制所有账号遵循标签要求。

## 6. 可扩展性基线

### 多环境隔离

- 在 Workload Account 中划分 dev / prod VPC 或使用命名空间、资源组进行隔离。

### 监控告警

- 启用云监控（CloudMonitor）：
  - ECS CPU 使用率 > 80% 时告警。
  - RDS 存储空间使用率 > 80% 时告警。

### 备份策略

- OSS：开启 Bucket 版本控制，并配置 30 天后转归档的生命周期规则。
- RDS：开启每日自动备份，保留 7 天。
- ECS：为云盘创建每周一次的快照计划，保留 2 周。

## ✅ 总结

- 账号治理：资源目录 + 管理 / 安全 / 业务账号分层。
- 身份安全：MFA、RAM 用户 / 角色、STS 临时凭证。
- 网络隔离：1 个 VPC（公有/私有子网），安全组默认拒绝。
- 合规安全：ActionTrail、Cloud Config、云安全中心、KMS。
- 资源部署：最小 ECS，按需部署 RDS / OSS。
- 治理扩展：Terraform/ROS、命名规范、标签策略、监控告警、备份快照。

通过上述基线，单用户场景也能在阿里云上建立符合 Landing Zone 要求的环境，并为未来扩展至团队或多账号场景奠定基础。

## 7. Pulumi IaC 实现指南

为便于快速落地上述基线，仓库提供了基于 Pulumi Python 的实现（目录：`iac_modules/pulumi`），与《docs/landingzone/alicloud-landingzone-mvp-single-account.md》设计保持一致，可直接复用或按需裁剪。

### 7.1 模块拆分

| 模块 | 说明 |
| --- | --- |
| `modules/identity/ram.py` | 创建 RAM 用户、用户组及策略绑定，覆盖 `ops-automation`、`audit-viewer` 等角色需求。 |
| `modules/storage/oss.py` | 管理 OSS 日志桶（版本控制 + 生命周期），用于 ActionTrail 与 Pulumi 状态存储。 |
| `modules/audit/actiontrail.py` | 启用 ActionTrail，将操作日志集中投递至指定 OSS Bucket。 |
| `modules/config_service/baseline.py` | 初始化 Cloud Config Recorder、Delivery Channel 与基础合规规则。 |
| `modules/network/vpc.py` | 构建单 VPC + 双可用区交换机的网络基线拓扑。 |
| `modules/security/security_groups.py` | 创建默认安全组及入/出站规则，默认仅放行必要出站流量。 |

### 7.2 配置结构

`config/alicloud/` 目录提供示例配置，按照 Landing Zone 设计拆分：

- `base.yaml`：区域与全局标签定义。
- `identity.yaml`：RAM 用户 / 用户组与策略映射。
- `storage.yaml`：ActionTrail 日志桶（版本控制 + 生命周期）。
- `network.yaml`：VPC / 交换机拓扑结构。
- `security.yaml`：安全组与默认规则。
- `audit.yaml`：ActionTrail 开关与 OSS 投递目标。
- `config-service.yaml`：Cloud Config 基线配置。

> ⚠️ 注意：`target_arn`、`assume_role_arn` 等字段需替换为真实账号 ID（`${AliUid}`）。

### 7.3 使用示例

```bash
# 安装依赖
pip install -r requirements.txt

# 指定配置目录（默认读取 config/，此处指向示例配置）
export CONFIG_PATH=config/alicloud

# Pulumi 登录（可选：使用 OSS backend 或 Pulumi Service）
pulumi login

# 预览或部署
pulumi preview --cwd iac_modules/pulumi
pulumi up --cwd iac_modules/pulumi
```

### 7.4 自动化与扩展建议

- 可通过 `.github/workflows/iac-pipeline-alicloud-landingzone-baseline.yaml`，结合 `pulumi/actions@v4` 构建 Preview + 主干自动部署流程，使用仓库 Secrets 管理 `ALICLOUD_ACCESS_KEY_ID/SECRET` 与 `PULUMI_ACCESS_TOKEN`。
- 根据生产需求扩展 Cloud Config 规则或引入企业版聚合器。
- 在安全组模块中追加环境专属规则（Prod/Test）。
- 利用 `pulumi stack` 拆分 dev / prod 状态，配合 GitHub Environments 审批。
