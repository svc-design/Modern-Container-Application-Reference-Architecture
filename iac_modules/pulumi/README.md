# ☁️ Pulumi Alicloud Landing Zone Baseline

该目录提供了与《docs/landingzone/alicloud-landingzone-mvp-single-account.md》一致的 Pulumi Python 实现，用于在单账号阿里云环境中快速落地身份、审计、配置合规、网络与安全基线。

## ✅ 模块拆分

| 模块 | 说明 |
| --- | --- |
| `modules/identity/ram.py` | 创建 RAM 用户、用户组以及策略绑定，覆盖 `ops-automation`、`audit-viewer` 等身份。 |
| `modules/storage/oss.py` | 管理 OSS 日志桶，支持版本控制与生命周期策略，用于 ActionTrail & Pulumi 状态。 |
| `modules/audit/actiontrail.py` | 启用 ActionTrail，将操作日志投递到指定 OSS Bucket。 |
| `modules/config_service/baseline.py` | 初始化 Cloud Config Recorder、Delivery Channel 与基础规则。 |
| `modules/network/vpc.py` | 构建单 VPC + 双可用区交换机的网络基线。 |
| `modules/security/security_groups.py` | 创建默认安全组及入站/出站规则，默认仅放行出站流量。 |

## 📂 配置结构

`config/alicloud/` 目录提供示例配置，按照 Landing Zone 设计拆分：

- `base.yaml`：区域与全局标签
- `identity.yaml`：RAM 用户/用户组与策略
- `storage.yaml`：ActionTrail 日志桶（版本控制+生命周期）
- `network.yaml`：VPC / 交换机拓扑
- `security.yaml`：安全组与规则
- `audit.yaml`：ActionTrail 开关与目标 OSS
- `config-service.yaml`：Cloud Config 基线配置

> ⚠️ 其中 `target_arn`、`assume_role_arn` 等字段需替换为实际账号 ID（`${AliUid}`）。

## 🚀 使用方式

```bash
# 安装依赖
pip install -r requirements.txt

# 设置配置目录（默认读取 config/，此处指向示例配置）
export CONFIG_PATH=config/alicloud

# Pulumi 登录（可选：使用 OSS backend 或 Pulumi Service）
pulumi login

# 预览或部署
pulumi preview --cwd iac_modules/pulumi
pulumi up --cwd iac_modules/pulumi
```

## 🔒 GitHub Actions 自动化

新增 `.github/workflows/iac-pipeline-alicloud-landingzone-baseline.yaml`，结合 `pulumi/actions@v4` 实现 Preview + 主干自动部署，使用 Secrets 管理 `ALICLOUD_ACCESS_KEY_ID/SECRET` 与 `PULUMI_ACCESS_TOKEN`。

## 🧩 扩展建议

- 根据生产需求扩展 Cloud Config 规则或引入企业版聚合器。
- 在安全组模块中追加环境专属规则（Prod/Test）。
- 利用 `pulumi stack` 拆分 dev/prod 状态，配合 GitHub Environments 审批。
