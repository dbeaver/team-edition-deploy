package cmd

import (
	"cbctl/tool"
	"github.com/spf13/cobra"
)

var configureHostCmd = &cobra.Command{
	Use:   "host",
	Short: "Configure the host machine",
	RunE: func(cmd *cobra.Command, args []string) error {
		return tool.Run(cmd, func(t *tool.Tool) error {
			return t.ConfigureHost()
		})
	},
}

func init() {
	configureCmd.AddCommand(configureHostCmd)
}
