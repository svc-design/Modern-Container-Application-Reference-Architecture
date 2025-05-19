package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var ansibleCmd = &cobra.Command{
	Use:   "ansible",
	Short: "🧪 执行 ansible-playbook",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🧪 调用 ansible-playbook ...")
		c := exec.Command("ansible-playbook", "-i", configPath+"/inventory.ini", configPath+"/site.yml")
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		c.Run()
	},
}
