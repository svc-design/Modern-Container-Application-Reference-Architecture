package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
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
	},
}
