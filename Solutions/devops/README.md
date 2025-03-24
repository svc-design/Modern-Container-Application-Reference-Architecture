# DevOPSPlatform

该解决方案使用 Gitlab, Harbor,ChartMuseum 等开源软件，构建的DevOPS平台解决方案通过 GitHub Actions 自动交付创建服务。

- IacOPS
- MLOPS
- DevSecOPS
- ChosOPS

# 架构图

![请在此添加图片描述](https://developer.qcloudimg.com/http-save/yehe-2810186/a4bab250e17d279a9a09c794249a09d6.png?qc_blockWidth=620&qc_blockHeight=435)

该解决方案使用以下开源软件：

- Gitlab
- Harbor/


# CICD
流水线配置文件
配置文件位于 .github/workflows/pipeline.yaml 由四个阶段组成：

- 构建测试：此阶段从源代码构建 APP, 并运行测试套件，以确保APP 正常工作。
- Docker 镜像：此阶段构建一个包含 APP 的 Docker 镜像。
- 设置 K3s：此阶段在远程服务器上设置 K3s 集群。
- 部署应用：此阶段将 APP 部署到 K3s 集群。

# Playook 角色说明

DevOPSPlatform 配置库由以下角色组成：

- app	        应用程序服务角色，提供应用程序运行所需的服务，如 Nginx、Docker、MySQL、Redis 等。
- chartmuseum	图表仓库角色，用于存储和管理 Kubernetes 图表。
- gitlab	代码仓库角色，用于存储和管理代码。
- k3s	Kubernetes 集群角色，用于管理 Kubernetes 集群。
- k3s-reset	Kubernetes 集群重置角色，用于重置 Kubernetes 集群。
- postgresql	PostgreSQL 数据库角色，用于提供 PostgreSQL 数据库服务。
- secret-manger	密钥管理角色，用于管理密钥。
- cert-manager	证书管理角色，用于管理证书。
- common	通用角色，包含一些常用的功能，如日志记录、监控等。
- harbor	容器镜像仓库角色，用于存储和管理容器镜像。
- k3s-addon	Kubernetes 集群插件角色，用于安装 Kubernetes 集群插件。
- mysql	        MySQL 数据库角色，用于提供 MySQL 数据库服务。
- redis	        Redis 数据库角色，用于提供 Redis 数据库服务。

## 触发器
管道由以下事件触发：

- 当打开或更新拉取请求时。
- 当代码推送到主分支时。
- 当工作流程手动调度时。

## 环境变量

在YAML文件或CI/CD流水线配置中定义的ENV变量：

- TZ: Asia/Shanghai：设置时区为Asia/Shanghai。
- REPO: "artifact.onwalk.net"：指定一个存储库的URL或标识符。
- IMAGE: base/${{ github.repository }}：基于GitHub存储库构建一个容器镜像名称。
- TAG: ${{ github.sha }}：将镜像标签设置为GitHub存储库的提交SHA。
- DNS_AK: ${{ secrets.DNS_AK }}：使用GitHub的密钥设置阿里云DNS访问密钥。
- DNS_SK: ${{ secrets.DNS_SK }}：使用GitHub的密钥设置阿里云DNS密钥。
- DEBIAN_FRONTEND: noninteractive：将Debian前端设置为非交互模式，这在自动化脚本中很有用，可防止交互提示。
- HELM_EXPERIMENTAL_OCI: 1：启用Helm中的实验性OCI（Open Container Initiative）支持，允许Helm与OCI镜像一起使用。

如需在自己的账号运行这个Demo，只需要将 https://github.com/open-source-solution-design/ObservabilityPlatform.git 这个仓库Fork 到你自己的Github账号下，同时在

Settings -> Actions secrets and variables: 添加流水线需要定义的 secrets 变量

Server 相关 secrets 变量

- HELM_REPO_USER            Artifact 仓库认证用户名
- HELM_REPO_REGISTRY      Artifact 仓库认证地址
- HELM_REPO_PASSWORD    Artifact 仓库认证密码
- HOST_USER                       部署K3S的主机OS登陆用户名
- HOST_IP                            部署K3S的主机IP地址
- HOST_DOMAIN                   部署K3S的主机域名
- SSH_PRIVATE_KEY             访问K3S的主机的SSH 私钥
- DNS_AK                             阿里云DNS 服务 AK (用于自动签发SSL证书和更新解析记录，发布ingress )
- DNS_SK                             阿里云DNS 服务 SK (用于自动签发SSL证书和更新解析记录，发布ingress )


# Ingress Endpoint

| name | URI |
| ---  | --- |
|      |     |

#  Repo Init

git submodule add https://github.com/svc-design/iac_modules.git iac_modules
git submodule add https://github.com/svc-design/playbook.git playbook
git submodule init
git submodule update
git submodule update --init --recursive
