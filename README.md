# 简介

一个面向多云环境和混合基础设施的一体化 DevOps 工具集。它以 AI 驱动为核心，覆盖基础设施部署、Kubernetes 资源保护、配置自动化、智能代码生成与发布、以及开发者网络优化等关键能力。


# 🔧 核心组件 & 工具

##  ✅ PulumiGo

- 基础设施即代码工具（IaC）
- 支持多环境、多云资源管理
- 自动创建 Kubernetes 集群、S3 存储、VPC 网络

## ✅ KubeGuard

- Kubernetes 应用 + 节点数据备份和恢复工具
- 结合 Velero + Rsync 实现混合备份
- 支持本地打包、S3 上传、离线恢复

## ✅ CraftWeave

- 配置管理与任务执行工具
- 类 Ansible CLI，支持配置文件 config.yaml
- 自动下发到目标节点，支持部署、更新、处理器量设置

## ✅ CodePRobot

- 智能代码生成与发布助手
- 监听 GitHub Issue/文档，自动生成修复代码 & PR
- 联动 CI/CD 实现日常构建/自动合并
- 支持与 CraftWeave 联动下发配置

## ✅ XStream

- 开发者本地网络加速器，支持加速访问 GitHub / ChatGPT / DockerHub 等连接


# 🌐 使用场景

- 多云资源统一部署与管理
- Kubernetes 应用全生命周期保护
- 配置自动下发与处理器部署
- GitHub 驱动智能代码合作 & PR 开发
- 处于复杂网络/GFW 环境下的开发高效体验


# 🌐 官方 GitHub 存储地址

- PulumiGo: https://github.com/svc-design/PulumiGo
- KubeGuard: https://github.com/svc-design/KubeGuard
- CraftWeave: https://github.com/svc-design/CraftWeave
- CodePRobot: https://github.com/svc-design/CodePRobot
- XStream: https://github.com/svc-design/xstream

欢迎添加关注、Star 、Fork，一起建设更智能、更跨环境的 DevOps 工具集成平台。

> 辅以 🤖 ChatGPT 之力，愿你我皆成 AIGC 时代的创造者与编织者 🚀
