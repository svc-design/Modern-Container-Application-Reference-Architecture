# 项目概述

该项目提供了一个简单的 Web 服务器，具有用于查询和插入数据的 REST API 端点。

# 代码结构
该项目具有以下目录结构：

```
example_pkg
|-- go.mod                  # Go 模块定义
|-- main.go                 # 主服务器入口点
|-- internal
|   |-- api                 # 包含 API 处理器的包
|   |   |-- api.go
|   |-- pkg
|       |-- functions.go    # 用于处理查询和插入的公共函数
|-- tests
|   |-- http_test.go        # HTTP API 端点的测试用例
```

# 函数列表
该项目定义了以下函数：

- pkg.QueryFunction() string - 处理查询并返回成功消息
- pkg.InsertFunction() string - 处理插入并返回成功消息
- api.QueryHandler(w http.ResponseWriter, r *http.Request) - 处理 /api/query 的 GET 请求
- api.InsertHandler(w http.ResponseWriter, r *http.Request) - 处理 /api/insert 的 POST 请求

# 构建和运行
要构建和运行该项目，请按照以下步骤操作：

- 克隆项目存储库并导航到项目目录。
- 安装项目依赖项：
  go mod init example_pkg
  go mod tidy
  go mod init
  go mod download
- 构建项目：go build
- 运行项目：./main

这将启动 Web 服务器，端口为 8080。您可以使用以下 URL 访问 API 端点：

- 查询 API：curl http://localhost:8080/api/query
- 插入 API：curl -X POST http://localhost:8080/api/insert

# 测试

## 单元测试

该项目包含用于 HTTP API 端点的测试用例。要运行测试，请执行以下命令：
go test

# CICD

## 流水线配置文件 
配置文件位于 .github/workflows/pipeline.yaml 由四个阶段组成：

1. 构建测试：此阶段从源代码构建 APP, 并运行测试套件，以确保APP 正常工作。
2. Docker 镜像：此阶段构建一个包含 APP 的 Docker 镜像。
3. 设置 K3s：此阶段在远程服务器上设置 K3s 集群。
4. 部署应用：此阶段将 APP 部署到 K3s 集群。

## 触发器

管道由以下事件触发：

- 当打开或更新拉取请求时。
- 当代码推送到主分支时。
- 当工作流程手动调度时。

## 环境变量

管道使用以下环境变量：

- TZ: 用于时间戳的时区。
- REPO: Onwalk 制品存储库的名称。
- IMAGE: 要构建的 Docker 镜像的名称。
- TAG: 要分配给 Docker 镜像的标签。

# API 参考

API 可以在本地通过 http://localhost:8080/ 访问。确保服务器正在运行后进行请求。

## 端点

| 端点 | 方法 | 描述 |
|---|---|---|
| / | GET | 返回问候消息 |
| /api/query | GET | 返回查询成功消息 |
| /api/insert | POST | 返回插入成功消息 |

## 示例请求

| 端点 | 请求方法 | 请求参数 | 预期输出 |
|---|---|---|---|
| / | GET | 无 | {"message": "Hello, world!"} |
| /api/query | GET | 无 | {"message": "查询成功"} |
| /api/insert | POST | 无 | {"message": "插入成功"} |


# 制品下载地址
1. GitHub Release: https://github.com/scaffolding-design/go/releases/tag/main
2. 容器镜像仓库  : artifact.onwalk.net/base/scaffolding-design/go:<git_commit_id>
