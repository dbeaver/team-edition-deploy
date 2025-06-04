package cmd

import (
	"cbctl/app"
	"github.com/spf13/cobra"
)

var configureCmd = &cobra.Command{
	Use:   "configure",
	Short: "Configure a product or the host machine",
	RunE: func(cmd *cobra.Command, args []string) error {
		return app.Run(cmd, func(t *app.App) error {
			return t.Start()
		})
	},
}

func init() {
	rootCmd.AddCommand(configureCmd)
}
