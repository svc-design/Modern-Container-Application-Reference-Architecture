package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var initCmd = &cobra.Command{
	Use:   "init",
	Short: "⚙️ 初始化依赖",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🔧 初始化依赖...")
		c := exec.Command("go", "mod", "tidy")
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		c.Run()
	},
}
