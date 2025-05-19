package cmd

import (
	"fmt"
	"os/exec"

	"github.com/spf13/cobra"
)

var exportCmd = &cobra.Command{
	Use:   "export",
	Short: "📤 导出 stack 状态",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("📤 导出 stack...")
		exec.Command("pulumi", "stack", "export", "--stack", env).Run()
	},
}

