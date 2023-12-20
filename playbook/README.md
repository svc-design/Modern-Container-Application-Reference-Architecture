# ansible-playbook

# Playook 角色说明

- Common 部分
  - common	        通用角色，包含一些常用的功能，如日志记录、监控等。
  - secret-manger	密钥管理角色，用于管理密钥。
  - cert-manager	证书管理角色，用于管理证书。
  - k3s	                用于创建 Kubernetes 集群。
  - k3s-reset	        用于重置 Kubernetes 集群。
  - k3s-addon	        用于安装 Kubernetes 集群插件。
  - app	                应用程序服务角色，提供应用程序运行所需的服务，如 Nginx、App_backend 等。
  - redis	        Redis 数据库角色，用于提供 Redis 数据库服务。
  - postgresql	        PostgreSQL 数据库角色，用于提供 PostgreSQL 数据库服务。

- DevOPSPlatform 使用的角色列表：
  - chartmuseum	        图表仓库角色，用于存储和管理 Kubernetes 图表。
  - gitlab	        代码仓库角色，用于存储和管理代码。
  - harbor	        容器镜像仓库角色，用于存储和管理容器镜像。
  - mysql	        MySQL 数据库角色，用于提供 MySQL 数据库服务。
- Federated-IdentityProvider 使用的角色列表：
  - openldap
  - keycloak
- ObservabilityPlatform 使用的角色列表：
  - alerting
  - clickhouse
  - node-exporter
  - observability-agent
  - observability-server
  - prometheus-transfer
  - promtail-agent
