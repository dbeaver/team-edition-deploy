package cmd

import (
	"cbctl/app"
	"github.com/spf13/cobra"
)

var startCmd = &cobra.Command{
	Use:   "start",
	Short: "Start a product",
	RunE: func(cmd *cobra.Command, args []string) error {
		return app.Run(cmd, func(t *app.App) error {
			return t.Start()
		})
	},
}

func init() {
	rootCmd.AddCommand(startCmd)
}
