# 方案概述


# CICD

## 流水线配置文件 
配置文件位于 .github/workflows/pipeline.yaml 由三个阶段组成：

1. 同步部署镜像：此阶段将同步chart包和应用镜像。
3. 设置 K3s：此阶段在远程服务器上设置 K3s 集群。
4. 部署应用：此阶段将chart包和应用镜像部署到 K3s 集群。

## 触发器

管道由以下事件触发：

- 当打开或更新拉取请求时。
- 当代码推送到主分支时。
- 当工作流程手动调度时。

## 环境变量

Pipeline env:

- TZ: 用于时间戳的时区。
- REPO: 制品存储库的名称。
- IMAGE: 要构建的 Docker 镜像的名称。
- TAG: 要分配给 Docker 镜像的标签。

Actions secrets:

- ADMIN_INIT_PASSWORD
- HELM_REPO_PASSWORD
- HELM_REPO_REGISTRY
- HELM_REPO_USER
- HOST_DOMAIN
- HOST_IP
- HOST_USER
- SSH_PRIVATE_KEY
- DNS_AK
- DNS_SK
