package cmd

import (
	"cbctl/app"
	"github.com/spf13/cobra"
)

var configureHostCmd = &cobra.Command{
	Use:   "host",
	Short: "Configure the host machine",
	RunE: func(cmd *cobra.Command, args []string) error {
		return app.Run(cmd, func(t *app.App) error {
			return t.ConfigureHost()
		})
	},
}

func init() {
	configureCmd.AddCommand(configureHostCmd)
}
