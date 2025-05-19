```
PulumiGo/
├── cmd/                       # Cobra 命令模块
│   ├── root.go               # 注册所有命令和全局参数
│   ├── init.go               # 初始化 go mod 依赖
│   ├── up.go                 # Pulumi 部署资源
│   ├── down.go               # Pulumi 销毁资源
│   ├── export.go             # 导出 stack 状态
│   ├── import.go             # 导入 stack 状态
│   └── ansible.go            # 执行 ansible-playbook（调用外部脚本）
│
├── internal/                 # 项目内部逻辑模块（不导出）
│   └── pulumi/infra.go       # Pulumi 基础设施部署定义
│
├── config/                   # 多环境配置目录（示例）
│   └── sit/                  # 示例环境 sit 配置文件（yaml/json 等）
│
├── scripts/                  # legacy 脚本（bash/sh）
│   └── run.sh                # 模拟入口，可被替换为 Go CLI
│
├── main.go                   # 程序主入口，调用 cmd.Execute()
├── go.mod                    # Go module 定义
├── go.sum                    # Go 依赖锁定文件
├── Makefile                  # 构建 & 调试命令
└── README.md                 # 项目说明
```

# 设计理念

- 区域	说明
- cmd/	所有子命令都集中在这里，Cobra 自动识别
- internal/	Go 推荐实践：内部模块放入 internal 避免外部导入
- pulumi/	用于封装 pulumi.Run() 中定义的基础设施资源
- scripts/	用于兼容旧 run.sh 方式，也方便对比
- config/	按环境管理 config & inventory 等配置
- Makefile	简化 build, run, up, down, ansible 等命令


# ✅ 示例命令

- make build
- 启动部署（Go + Pulumi） ./PulumiGo up --env sit
- 导出 stack 状态 ./PulumiGo export
- 调用 ansible 脚本 ./PulumiGo ansible
