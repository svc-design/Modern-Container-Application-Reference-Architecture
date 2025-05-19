package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"PulumiGo/internal/pulumi"
)

var upCmd = &cobra.Command{
	Use:   "up",
	Short: "🚀 部署资源",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🚀 正在部署资源...")
		c := exec.Command("pulumi", "up", "--stack", env, "--non-interactive", "--yes")
		c.Env = append(os.Environ(), "PULUMI_CONFIG_PASSPHRASE_FILE="+os.Getenv("HOME")+"/.pulumi-passphrase")
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		c.Run()

		err := pulumi.DeployInfrastructure()
		if err != nil {
			fmt.Println("❌ 部署失败:", err)
			os.Exit(1)
		}
		fmt.Println("✅ 部署完成")
	},
}
