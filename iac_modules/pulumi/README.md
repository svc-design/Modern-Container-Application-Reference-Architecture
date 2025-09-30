# Pulumi IaC 本地调试指南

该目录包含基于 Pulumi Python 的多云基础设施模板，支持阿里云、AWS 以及 Vultr。本文档介绍本地调试所需的前置条件、环境变量以及辅助脚本的使用方式，便于与 GitHub Actions 流水线保持一致。

## 1. 前置条件

在开始之前，请确保本地环境已经安装以下工具：

- Python 3.9 及以上版本
- Pulumi CLI（推荐使用最新版，可通过 `curl -fsSL https://get.pulumi.com | sh` 安装）
- AWS CLI（用于访问 S3 backend 与 AWS 资源）
- 已准备好仓库根目录的依赖：
  ```bash
  pip install -r requirements.txt
  ```

> 建议使用虚拟环境（如 `python -m venv .venv`）隔离依赖，并在执行 Pulumi 命令前激活它。

## 2. 必需环境变量

GitHub Actions 与本地调试共享相同的一组环境变量。根据目标云厂商选择性地设置凭据，但 **Pulumi 状态管理必须使用 S3 backend**。

| 变量名 | 说明 |
| --- | --- |
| `PULUMI_ACCESS_TOKEN` | 使用 Pulumi Service 时需要的访问令牌。若仅使用 S3 backend，可留空。 |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | 用于访问 AWS 资源和 S3 状态桶的凭据。 |
| `ALICLOUD_ACCESS_KEY` / `ALICLOUD_SECRET_KEY` | 部署阿里云资源时所需的访问密钥。 |
| `VULTR_API_KEY` | 部署 Vultr 资源时使用的 API Key。 |
| `IAC_STATE_BACKEND` | Pulumi 后端地址，**必须**为 `s3://<bucket>/<path>` 形式，以确保状态文件全部存储在 S3。 |
| `PULUMI_STACK` | 当前操作的 Stack 名称，例如 `dev`、`prod`。 |
| `CONFIG_PATH` | （可选）指定配置目录，默认根据云厂商选择 `config/<provider>`。 |

> 兼容变量：脚本同样支持 `IAC_State_backend` 形式的环境变量，以便与现有流水线兼容。

S3 backend 的 Bucket 需提前创建，并为 Pulumi 访问角色授予读写权限。例如：

```bash
export IAC_STATE_BACKEND="s3://my-pulumi-state-bucket/modern-app"
```

## 3. `iac_run.sh` 辅助脚本

为方便本地调试，目录下新增 `iac_run.sh`，与 GitHub Actions 的命令约定保持一致。执行前请确保以上环境变量均已配置。

```bash
cd iac_modules/pulumi
./iac_run.sh <命令>
```

支持的命令如下：

| 命令 | 对应操作 |
| --- | --- |
| `init` | 登录 S3 backend 并初始化（或选择）指定的 Stack。 |
| `create` | 使用 `pulumi up --yes --skip-preview` 创建/更新资源。 |
| `migrate` | 调用 `pulumi refresh --yes`，同步实际资源状态到后端。 |
| `upgrade` | 执行常规 `pulumi up --yes` 以滚动更新。 |
| `backup` | 通过 `pulumi stack export` 导出状态文件到 `backups/` 目录。可通过 `PULUMI_BACKUP_DIR` 覆盖输出路径。 |
| `restore <文件>` | 从指定备份文件执行 `pulumi stack import`。也可设置 `BACKUP_FILE` 环境变量。 |
| `destroy` | 运行 `pulumi destroy --yes` 清理当前 Stack 资源。 |

查看帮助信息：

```bash
./iac_run.sh --help
```

## 4. 配置目录与多云支持

Pulumi 入口脚本会根据配置文件中的根节点自动选择部署目标：

- `alicloud`：执行阿里云 Landing Zone 模块。
- `aws`：执行 AWS 基线模块。
- `vultr`：执行 Vultr Landing Zone 模块。

可通过设置 `CONFIG_PATH` 指向自定义目录，例如：

```bash
export CONFIG_PATH="config/vultr/dev"
```

随后运行 `./iac_run.sh init` 与 `./iac_run.sh create` 即可完成 Vultr 基线的部署与更新。

## 5. 常见问题

1. **Pulumi 提示未登录**：确认是否正确设置了 `IAC_STATE_BACKEND`（或 `IAC_State_backend`）并具备相应的 S3 访问权限。
2. **凭据不足**：依赖的云厂商访问密钥需具备创建/查询基础资源的权限，建议在 IAM 中专门为 IaC 运行创建角色或子账号。
3. **Python 依赖缺失**：确保已经在仓库根目录执行 `pip install -r requirements.txt`，Pulumi 才能正确加载各个云厂商的 SDK。

如需更多关于资源结构与模块的细节，请查阅 `modules/` 目录或仓库中的云基线设计文档。
