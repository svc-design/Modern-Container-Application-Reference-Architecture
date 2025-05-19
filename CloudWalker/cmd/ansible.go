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
		fmt.Println("🧪 执行 ansible-playbook...")
		c := exec.Command("ansible-playbook", "-i", fmt.Sprintf("%s/inventory.ini", configPath), fmt.Sprintf("%s/site.yml", configPath))
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		c.Run()
	},
}

