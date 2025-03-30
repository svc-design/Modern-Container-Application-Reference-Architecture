# ☁️ Pulumi 多模块 AWS IaaS 模板

该目录基于 Pulumi 构建，支持以下模块：

## ✅ 模块支持

- VPC + 子网（自动分配 CIDR，支持 enabled 控制）
- 安全组（通过 firewall.yaml 控制 ingress/egress）
- EC2 实例（支持 spot、AMI keyword、user_data、自动标签）
- AMI 自动识别（支持 `Ubuntu 22.04`, `Rocky Linux 8.10` 等）
- Pulumi Credentials 自动加载 ~/.aws/profile
- 环境配置文件支持多目录（如 `config/sit/`, `config/prod/`）

## 🚀 快速部署
```bash
初始化并部署 bash scripts/run.sh sit up

## 📂 配置说明

# config/sit/instances.yaml

```yaml
instances:
  - name: master-1
    ami: Ubuntu 22.04
    type: t3.micro
    subnet: public-subnet-1
    disk_size_gb: 20
    lifecycle: spot
    ttl: 1h
```yaml

## 🧹 清理资源

删除资源 + 刷新状态
- bash scripts/run.sh sit down 
- pulumi refresh --yes

## 📦 依赖
Python >= 3.8
pip install -r requirements.txt
AWS CLI 已配置 ~/.aws/credentials
