# 项目概述
该项目使用 Flask 和 Connexion 实现了一个简单的 API，包括两个端点：`/` 用于返回问候消息，`/user` 用于创建用户。

# 代码结构
项目的结构如下：
- `src/example_pkg/core.py`：包含主要逻辑和 API 端点。
- `main.py`：初始化 Flask 应用程序，设置 CORS 并与 Connexion 集成。
- `openapi.yaml`：定义 API 的 OpenAPI 规范。
- `tests/test_main.py`：主应用逻辑的单元测试。
- `tests/test_units.py`：特定功能的额外单元测试。

# 函数列表
1. `index_view`：返回问候消息。
2. `create_user`：根据提供的 JSON 负载创建用户。

# 构建与运行
要构建和运行项目，请按照以下步骤进行：
1. 安装依赖：`apt-get install -y --no-install-recommends python3-pip`
2. 安装依赖项：`pip3 install -r requirements.txt`
3. 安装构建工具：`python3 -m pip install build`
4. 构建项目：`python3 -m build`
5. 运行应用：`python3 main.py`

# 测试
## 测试文件
- `tests/test_main.py`：包含主应用逻辑的单元测试。
- `tests/test_units.py`：包含特定功能的额外单元测试。

## 运行测试
使用以下命令运行测试：
```bash
pytest tests/
```

# API 

## 文档
API 的 OpenAPI 规范定义在 openapi.yaml 文件中。您可以使用该文件生成 API 文档。

## 访问API
API 可以在本地通过 http://localhost:80/ 访问。确保服务器正在运行后进行请求。

- 端点：/
  - 方法： GET
  - 描述： 返回问候消息。
  - 示例请求：curl http://localhost:80/
  - 预期输出：{"message": "Hello, world!"}

- 端点：/user
  - 方法： POST
  - 描述： 根据提供的 JSON 负载创建用户。
  - 示例请求：curl -X POST -H "Content-Type: application/json" -d '{"username": "Bard", "age": 20}' http://localhost:80/user
  - 预期输出：{"username": "Bard", "age": 20}

# CICD

- 流水线配置文件 .github/workflows/pipeline.yaml 由四个阶段组成：

1. 构建测试：此阶段从源代码构建 sysinfo 库, 并运行测试套件，以确保 sysinfo 库正常工作。
2. Docker 镜像：此阶段构建一个包含 sysinfo 库的 Docker 镜像。
3. 设置 K3s：此阶段在远程服务器上设置 K3s 集群。
4. 部署应用：此阶段将 sysinfo 库部署到 K3s 集群。

- 触发器, 管道由以下事件触发：

- 当打开或更新拉取请求时。
- 当代码推送到主分支时。
- 当工作流程手动调度时。

- 环境变量, 管道使用以下环境变量：

- TZ: 用于时间戳的时区。
- REPO: Onwalk 制品存储库的名称。
- IMAGE: 要构建的 Docker 镜像的名称。
- TAG: 要分配给 Docker 镜像的标签。

# 制品下载地址
1. GitHub Release: https://github.com/scaffolding-design/python/releases/tag/main
2. 容器镜像仓库  : artifact.onwalk.net/base/scaffolding-design/python:<git_commit_id>
其中，<git_commit_id> 是 Git 提交 ID。
