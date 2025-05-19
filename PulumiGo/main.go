package main

import (
	"fmt"
	"os"

	"PulumiGo/cmd"
)

func main() {
	fmt.Println("🔐 Pulumi 密码文件已加载:", os.Getenv("HOME")+"/.pulumi-passphrase")
	fmt.Println("\n🧰 PulumiGo - 多环境自动化管理器 (Go + Pulumi Native)")
	fmt.Println(`\n用法:
  PulumiGo --env [环境] [命令]
  STACK_ENV=prod CONFIG_PATH=config/prod PulumiGo up

支持命令:
  init      ⚙️ 初始化依赖
  up        🚀 部署资源
  down      🔥 销毁资源
  export    📤 导出 stack 状态
  import    📥 导入 stack 状态
  ansible   🧪 执行 ansible-playbook
  help      📖 显示帮助\n`)

	if err := recover(); err != nil {
		fmt.Fprintf(os.Stderr, "💥 panic: %v\n", err)
		os.Exit(2)
	}
	cmd.Execute()
}
