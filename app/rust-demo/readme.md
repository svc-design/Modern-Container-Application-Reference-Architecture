
# 概述
这个项目是一个使用 Actix-web 框架搭建的简单 HTTP 服务器，提供两个 API：查询 (/api/query) 和插入 (/api/insert)。同时，它包含了跨域资源共享 (CORS) 的支持。

# 技术框架 

- Actix-web: 异步 Web 框架，用于构建高性能和可伸缩的 Web 应用,支持异步请求处理和并发处理。
- Actix-cors: 中间件，用于添加跨域资源共享 (CORS) 支持。允许前端从不同的源（域、协议或端口）请求资源。
- Serde: 序列化/反序列化库，用于将结构体转换为 JSON 格式。

# 代码结构

```
my_rust_server
|-- src
|   |-- lib.rs
|   |-- main.rs
|-- tests
|   |-- integration_test.rs
```

# 函数列表

- query_handler()：用于处理 /api/query 端点的请求
- insert_handler()：用于处理 /api/insert 端点的请求
- run_server()：用于启动服务

# 构建与运行

在 Cargo.toml 中添加依赖：actix-web, actix-cors, 和 serde。

- 编译项目 cargo build
- 运行项目 cargo run
- 运行测试 cargo test

运行 cargo run 命令启动服务器。服务器将在 127.0.0.1:8080 上监听请求。

# 测试 API：

使用工具如 curl 或浏览器，访问 http://127.0.0.1:80/api/query 和 http://127.0.0.1:80/api/insert，验证 API 的功能和跨域支持。
测试命令

- 查询 API 测试 curl http://localhost:80/api/query
- 插入 API 测试 curl -X POST http://localhost:80/api/insert

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

API 可以在本地通过 http://localhost:80/ 访问。确保服务器正在运行后进行请求。

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
1. GitHub Release: https://github.com/scaffolding-design/rust/releases/tag/main
2. 容器镜像仓库  : artifact.onwalk.net/base/scaffolding-design/rust:<git_commit_id>
