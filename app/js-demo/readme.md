# 项目介绍

该项目使用 Node.js 和 Express 构建了一个返回 `/api/list` 的服务。前端使用 React 和 Axios 来请求后端服务。

## 技术框架

* Vue3
* Axios
* Node.js
* Express

# 前端

1. 目录结构
```
frontend/
|-- src
|   |-- App.vue
|   |-- main.js
|   |-- components
|   |   |-- List.vue
|   |-- router.js
|-- package.json
```
2. 依赖 
```
Vue 3 
Vue Router
Axios
```

3. 构建命令

- 安装依赖 npm install
- 启动开发服务器 npm run serve
- 构建生产版本 npm run build

4. curl 测试命令
# 测试获取列表数据 curl http://localhost:8080


# 后端

1. 目录结构
```
your-backend-project
|-- app.js
|-- package.json
|-- app
|   |-- controllers
|   |   |-- ListController.js
|   |-- models
|   |   |-- List.js
|   |-- routes
|   |   |-- index.js
```

2. API 接口说明 GET /api/list: 获取包含两个用户信息的列表
3. 依赖 Express
4. 构建命令
- 安装依赖 npm install
- 启动服务器 npm start
5. curl 测试命令
- 测试获取列表数据 curl http://localhost:3000/api/list

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

# API

该 API 提供一个端点用于获取用户列表。

## API 端点

| 端点 | 方法 | 描述 |
|---|---|---|
| `/list` | **GET** | 获取用户列表 |

## 示例请求

| 端点 | 请求方法 | 请求参数 | 预期输出 |
|---|---|---|---|
| `/list` | **GET** | **无** | `[{"id": 1, "name": "用户 1"}, {"id": 2, "name": "用户 2"}]` |

## 前端

该 API 的前端代码位于 `frontend` 目录中。`List.vue` 组件负责显示用户列表。

## 后端

该 API 的后端代码位于 `backend` 目录中。`ListController.getList()` 方法负责获取用户列表。

# 制品下载地址

1. GitHub Release: [https://github.com/scaffolding-design/javascript/releases/tag/main](https://github.com/scaffolding-design/javascript/releases/tag/main)
2. 容器镜像仓库  : 
    - artifact.onwalk.net/base/scaffolding-design/javascript-frontend:<git\_commit\_id>
    - artifact.onwalk.net/base/scaffolding-design/javascript-backend:<git\_commit\_id>
