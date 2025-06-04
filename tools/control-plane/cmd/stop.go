package cmd

import (
	"cbctl/app"
	"github.com/spf13/cobra"
)

var stopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop a product",
	RunE: func(cmd *cobra.Command, args []string) error {
		return app.Run(cmd, func(t *app.App) error {
			return t.Stop()
		})
	},
}

func init() {
	rootCmd.AddCommand(stopCmd)
}
