package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var downCmd = &cobra.Command{
	Use:   "down",
	Short: "🔥 销毁资源",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🔥 正在销毁资源...")
		c := exec.Command("pulumi", "destroy", "--stack", env, "--non-interactive", "--yes")
		c.Env = append(os.Environ(), "PULUMI_CONFIG_PASSPHRASE_FILE="+os.Getenv("HOME")+"/.pulumi-passphrase")
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		c.Run()
	},
}
