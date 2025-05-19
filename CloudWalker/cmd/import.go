package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var importCmd = &cobra.Command{
	Use:   "import",
	Short: "📥 导入 stack 状态",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("📥 正在导入 stack 状态...")
		c := exec.Command("pulumi", "stack", "import", "--stack", env)
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		c.Stdin = os.Stdin // 允许从输入导入
		c.Run()
	},
}
