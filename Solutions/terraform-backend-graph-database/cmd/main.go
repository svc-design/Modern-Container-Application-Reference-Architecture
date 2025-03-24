package main

import (
    "log"

    "github.com/hashicorp/terraform-plugin-sdk/v2/plugin"
    "github.com/yourusername/terraform-backend-GraphDB/internal/backend"
)

func main() {
    // 启动 Terraform 后端插件
    err := plugin.Serve(&plugin.ServeOpts{
        BackendFunc: backend.New, // 使用自定义后端实现
    })
    if err != nil {
        log.Fatal(err) // 如果启动失败，输出错误并退出
    }
}
