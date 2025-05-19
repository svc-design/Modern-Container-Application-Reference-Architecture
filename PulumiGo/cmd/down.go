package cmd

import (
	"fmt"
	"os/exec"

	"github.com/spf13/cobra"
)

var downCmd = &cobra.Command{
	Use:   "down",
	Short: "🔥 销毁资源",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🔥 正在销毁资源...")
		exec.Command("pulumi", "destroy", "--yes", "--stack", env).Run()
	},
}
