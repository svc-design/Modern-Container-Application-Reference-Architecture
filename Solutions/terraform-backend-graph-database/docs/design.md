terraform-backend-GraphDB/
├── cmd/
│   └── main.go                 # 主程序入口
├── internal/
│   ├── backend/
│   │   ├── backend.go          # Terraform 后端接口实现
│   │   ├── state.go            # 状态存储管理
│   │   ├── locker.go           # 锁定机制实现
│   ├── graphdb/
│   │   ├── client.go           # Nebula Graph 数据库连接与操作
│   │   ├── schema.go           # 图数据库 schema 定义
│   │   ├── resources.go        # 资源 CRUD 实现
│   ├── cloud/
│   │   ├── aws.go              # AWS 平台资源处理
│   │   ├── gcp.go              # GCP 平台资源处理
│   │   ├── azure.go            # Azure 平台资源处理
│   │   ├── alicloud.go         # Alicloud 平台资源处理
├── pkg/
│   ├── config/
│   │   └── config.go           # 配置解析和管理
│   ├── log/
│   │   └── logger.go           # 日志处理
├── examples/
│   └── main.tf                 # Terraform 配置示例
├── go.mod                      # Go 依赖配置
├── go.sum                      # Go 依赖锁定文件
├── README.md                   # 项目说明
└── Makefile                    # 构建和测试指令
