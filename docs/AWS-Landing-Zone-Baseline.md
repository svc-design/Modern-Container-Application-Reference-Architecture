# AWS Landing Zone Baseline（单用户最小需求清单）

本清单聚焦单用户（Owner）管理场景，仍需满足 Landing Zone 在账号治理、安全、网络、资源隔离与合规扩展性方面的基础要求。

## 1. 账号与身份基线

### AWS Organizations
- 启用 AWS Organizations，避免所有资源集中在管理账号（root account）下。
- 即使只有单用户，也建议采用组织化的账号布局，便于后续扩展与治理。

### 账号分层（最小 3 个账号）
1. **Management / Root Account**：用于组织与账单管理，不直接部署工作负载。
2. **Shared Services / Security Account**：集中托管 CloudTrail、Config、GuardDuty 等全局安全与日志服务。
3. **Workload Account**：部署 EC2、EKS、RDS 等业务资源。

### IAM 基线
- 启用根账号（root user）多因素认证（MFA），禁止日常使用 root 用户登录。
- 创建至少一个具备管理员权限的 IAM 用户，并启用 MFA。
- 使用 IAM Role（短期凭证）替代长期 Access Key，提升安全性并便于自动化扩展。

## 2. 网络基线

### VPC
- 每个 Workload Account 至少创建一个 VPC，满足业务与安全隔离需求。
- 设置公有子网（对外服务）与私有子网（数据库、内部应用）。

### 出站访问
- 需要访问外部互联网的私有子网可配置 NAT Gateway；成本敏感场景可选择小型实例自建 NAT。

### 安全组策略
- 默认拒绝所有入站流量。
- 仅对受信任的源 IP 开放 SSH 与 HTTPS 等必要端口。

## 3. 安全与合规基线

### 日志与审计
- 启用 AWS CloudTrail（跨区域），日志集中存储于 Security Account 的 S3 存储桶。
- 开启 AWS Config，监控资源配置与合规性。

### 威胁检测
- 在 Security Account 中集中启用 Amazon GuardDuty。

### 加密
- 至少创建一个客户管理的 KMS CMK（Customer Managed Key）用于加密需求，便于审计与密钥轮换。

## 4. 资源与环境基线

### 最小计算资源
- 部署一台 t3.small 或 t4g.small EC2 实例，作为跳板机或轻量级测试环境。
- 可使用 Lightsail 做实验性工作负载，但不建议作为正式 Landing Zone 资源。

### 镜像与 AMI
- 优先选用官方 Amazon Linux 2023 或 Ubuntu 官方 AMI，确保安全与持续更新。

## 5. 自动化与治理基线

### 基础 IaC
- 使用 Terraform、AWS Control Tower，或 AWS Landing Zone Accelerator（LZA）实现基础设施即代码自动化。
- 若预算有限，可先行采用 Terraform 管理基础结构。

### 命名规范
- 采用格式：`lz-<account>-<env>-<service>`。
  - 例如：`lz-workload-dev-vpc1`、`lz-security-log-bucket`。

### 标签策略
- 必备标签：`owner=haitao`，`env=dev/prod`，`cost-center=personal`。
- 在 AWS Organizations 中启用 Tag Policies 统一约束。

## 6. 可扩展性基线

### 多环境逻辑隔离
- 即使单用户，也要预先规划 dev / prod 等逻辑环境，便于未来扩展。

### 监控
- 启用 CloudWatch Metrics（默认提供）。
- 至少配置一项 CloudWatch Alarm，如 EC2 CPU 使用率超过 80% 时报警。

### 备份策略
- 制定 Backup Plan：
  - EC2：每日创建 EBS Snapshot，保留 7 天。
  - RDS：启用自动快照。

---

**总结：**
- 组织与账号治理：Organizations + 3 个账号（Root / Security / Workload）。
- 安全：CloudTrail、Config、GuardDuty、MFA、IAM Role。
- 网络：最小 VPC（公有/私有子网 + 基础安全组）。
- 资源：1 台小型 EC2 + 官方 AMI。
- 治理：Terraform/IaC + 命名规范 + 标签策略。
- 运维：CloudWatch 基础告警 + 自动快照/备份。
