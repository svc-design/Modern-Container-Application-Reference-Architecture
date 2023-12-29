# 现代容器应用参考架构

我们将现代应用架构定义为具有四个特性的架构：可扩展性、可移植性、弹性和敏捷性。尽管现代架构存在许多不同的方面，但这些是基础。

- 可扩展性 - 能够快速无缝地向上或向下扩展，以应对全球范围内需求的增减。
- 可移植性 - 易于在多种类型的设备和基础设施上部署，无论是在公共云还是本地环境中。
- 弹性 - 能够在不同可用区域、云或数据中心的新启动的集群或虚拟环境中进行故障转移。
- 敏捷性 - 通过自动化的CI/CD管道实现更新，具有更高的代码速度和更频繁的代码推送。

# 现代容器应用参考架构

![PlantUML Diagram](https://www.plantuml.com/plantuml/png/XPL1JnD15CVlxrECN3nnwis3WPIcD9A6A7UpRL_BfhkpP6QsQ8o9qKXY0ke1HNlGH2NqOglnO3WGlWopYz_26RAbmylkq5Ft_N_px__jpBokI1K8bSOHtEbXF-J87ZRgMwljvaQ3TQD0Ie15eHcgzRHJRpcbpJHAun0eunJM0z59X5FOI8RkWZN4dNwKxBgc8ebHRMCgdU9gX4B50Gy6wBhLex0xt4vIYMu84VGDwLJQWv0_SN-r_SZrtcmr0uMxmLE0kqp_6ETlP_hRApqTNvo-WNuIzL2mfJKSOPJinCWLQ_1HA19klo-nPy3CnsrfzFX1sa71KQ4i4OSr2S-lVRTGgf0F_9uM8gP49Qxc9VRIhWeJxZUs734cQc4Cy-rdoyltYtrczzZ5sNb-E2b4AnLdmaZ_NX_aPrCeder4tWnLXZMtH5kc4iLf8rIoEDmCOCNYW9guUdggFq-oFnEzjmz57Wz1ujr6-ir8-5j8lrbfbrSNm80jFX0efTiVrKXd7gR2W7JZOIeCIZkmSyCWsT6nFZzoybE5fYydoXVJv5L4-MAmZxO-7q16qkzcboTxUlyZp0TT9R0OUvM8EmIl86UDkMylnldNOrYCHEAJVVYL7Kprpq_wvGJ0Z42hEyFF89SdtxClxs5HAxcs5lixomz_bs73MhLETyR7UOteBdcv6qOho7lstmx-0m00)

本仓库提供了现代容器应用的参考架构。它侧重于以下关键原则：

- 平台无关性：架构旨在做到平台无关性，让您可以在不同的容器编排平台上部署应用，例如Kubernetes（k8s）或轻量级替代品如k3s。
开源软件优先：优先考虑开源软件（OSS），确保架构基于强大且广泛采用的工具和技术构建。
- 一切以代码定义：使用基础设施即代码（IaC）定义和配置应用所需的所有资源，确保一致性、可复制性和可扩展性。
- CI/CD自动化：使用GitHub CI实现持续集成和持续部署（CI/CD）管道，实现自动化构建、测试和部署过程。
- 安全意识开发：在架构的每个阶段实施安全最佳实践，包括容器化构建、安全容器仓库（如Harbor）以及服务间的安全通信。
- 分布式存储：架构包含分布式存储解决方案，以确保应用数据的高可用性和可扩展性。

# 工具链

以下工具在此参考架构中使用：

- 管道：GitHub CI
- IaC工具：Pulumi/terraform
- 代码仓库：GitHub
- 容器仓库：Harbor
- 监控：
  - 日志：Loki
  - 跟踪：Deepflow
  - 指标：Prometheus
  - 通知：Alertmanager
- 数据存储：Clickhouse
- 可视化：Grafana
- 集群管理：Kubernetes（k8s） 轻量级Kubernetes（k3s）
- 入口：Nginx
- DNS: DNS服务SaaS

# 入门

要开始使用此参考架构，请按照以下步骤操作：


# 文档

1. 多集群运维(一)：自动化交付、构建、部署、发布、监控。https://cloud.tencent.com/developer/article/2373761
2. 多集群运维(二)：应用渐进发布。https://cloud.tencent.com/developer/article/2375570

# 问题

- APISIX和External DNS集成：APISIX和External DNS合作存在问题，导致无法自动更新DNS解析记录。
- FluxCD、Flagger和APISIX入口的指标收集：使用FluxCD、Flagger和APISIX入口时指标收集的兼容性和效率尚待验证。
- 金丝雀发布监控：金丝雀发布的监控状态仍待验证。

# 待办事项

- 多集群运维(三)：微服务应用的渐进发布。
- 多集群运维(四)：应用系统的多维监控。
- 多集群运维(五)：应用系统的脆弱性测试。
- 多集群运维(六)：应用系统运维与AIOps。
- SSL证书管理
  - 申请 Let's Encrypt 证书并保存到 Vault
  - 配置 CertManager 以从 Vault 读取证书

# 贡献

我们欢迎社区对此参考架构的贡献。如果您有任何建议、改进或错误修复，请随时提交拉取请求。

# 许可

此参考架构根据GPL V3许可发布。
