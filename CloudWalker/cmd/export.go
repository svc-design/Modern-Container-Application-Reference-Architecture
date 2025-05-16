package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var exportCmd = &cobra.Command{
	Use:   "export",
	Short: "📤 导出 stack 状态",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("📤 正在导出 stack 状态...")
		c := exec.Command("pulumi", "stack", "export", "--stack", env)
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		c.Run()
	},
}

