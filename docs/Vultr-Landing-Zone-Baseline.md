# Vultr Landing Zone Baseline 单用户最小需求清单

- 主账号启用多因素认证（MFA），将 root 和 API Key 分离管理。
- 配置 1 个 VPC（含公有与私有子网）以及 1 个 Firewall Group。
- 确认数据加密与审计日志已启用，并限制 root key 使用。
- 部署 1 台基于官方镜像的最小规格 VPS。
- 通过 Terraform 或 Pulumi 管理资源，遵循统一命名规范并添加标签。
- 制定 1 套备份策略并启用基础监控。
