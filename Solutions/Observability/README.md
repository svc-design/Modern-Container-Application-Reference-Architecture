# ObservabilityPlatform

该解决方案使用 ClickHouse、Neo4j、VectorDB、PromQL、LogQL、OpenTracing、Prometheus、Grafana、AlertManager 和 DeepFlow 等开源工具。开源的可观察性平台解决方案通过 GitHub Actions 自动交付创建服务。

# 架构图

![请在此添加图片描述](https://developer.qcloudimg.com/http-save/yehe-2810186/a4bab250e17d279a9a09c794249a09d6.png?qc_blockWidth=620&qc_blockHeight=435)

该解决方案使用以下开源软件：

- 数据收集：使用 Prometheus、OpenTelemetry，Deepflow-agent，Promtail，cloudquery 等工具从系统组件、应用程序和云账户数据同步
- 数据存储：使用 ClickHouse、Neo4j、VectorDB 等工具存储观测数据。
- 数据分析：使用 Prometheus、Grafana 等工具分析观测数据。
- 数据可视化：使用 Grafana 等工具以可视化的方式呈现观测数据。


# CICD
流水线配置文件
配置文件位于 .github/workflows/pipeline.yaml 由四个阶段组成：

- 构建测试：此阶段从源代码构建 APP, 并运行测试套件，以确保APP 正常工作。
- Docker 镜像：此阶段构建一个包含 APP 的 Docker 镜像。
- 设置 K3s：此阶段在远程服务器上设置 K3s 集群。
- 部署应用：此阶段将 APP 部署到 K3s 集群。

# Playook 角色说明

可观察性平台配置库由以下角色组成：

node-exporter: 部署 node_exporter 来收集系统指标。
prometheus-transfer: 转发 Prometheus 将指标传输到远程存储。
promtail-agent: 部署 Promtail 从节点收集日志。
k3s: 提供管理 k3s 集群的任务。
k3s-addon: 部署 k3s 附加组件。
k3s-reset: 将 k3s 集群重置为初始状态。
secret-manger: 部署 secret-manager 来管理敏感数据。
cert-manager: 部署 cert-manager 以颁发 TLS 证书。
clickhouse: 部署 Clickhouse 以存储和分析时序数据。
observability-agent: 在 k3s 节点上部署可观察性代理。
observability-server: 部署可观察性服务器组件。
mysql: 部署 MySQL 以存储 Deepflow数据以及Grafana配置信息。
alerting: 存储 Prometheus Alertmanager Rules 。

容器集群相关相关的 Ansible playbook roles

非容器集群相关的 Ansible playbook roles

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

客户端相关 secrets 变量

- APP_HOST_USER                       部署APP集群的master 主机OS登陆用户名
- APP_HOST_IP                            部署APP集群的master 主机IP地址
- APP_HOST_DOMAIN                   部署APP集群的master 主机IP域名

# API Endpoint

| name | URI |
| ---  | --- |
| querying(promql, logql, tempo) | http://data-gateway.<domian>                            |
| metrics_query                  | https://prometheus.<domian>/api/v1/query                |
| metrics_remote_write           | https://prometheus.<domian>/api/v1/remote/write         |
| logql_remote_query             | https://data-gateway.<domian>/loki/api/v1/query         |
| logql_remote_write             | https://data-gateway.<domian>/loki/api/v1/push          |
| traces_tempo_push              | https://data-gateway.<domian>/tempo/api/push            |
| traces_zipkin_push             | https://data-gateway.<domian>/api/v2/spans              |
| traces_oltp_push               | https://data-gateway.<domian>/v1/traces                 |
| Query Traces                   | https://data-gateway.<domian>/api/traces/{traceId}      |
| Query Traces (JSON)	         | https://data-gateway.<domian>/api/traces/{traceId}/json |


# Reference

1. 可观测平台-2: 开源解决方案
 https://cloud.tencent.com/developer/article/2363793
3. 可观测平台-3: 应用系统告警项
https://cloud.tencent.com/developer/article/2370478
可观测平台-3.1: Web前端/后端/网关 监控项: 
https://cloud.tencent.com/developer/article/2370608
可观测平台-3.2: Cache/MQ/TQ 中间件监控项原创: 
https://cloud.tencent.com/developer/article/2370613
可观测平台-3.3: 数据库监控项：
https://cloud.tencent.com/developer/article/2370615
