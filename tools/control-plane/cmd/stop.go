package cmd

import (
	"cbctl/tool"
	"github.com/spf13/cobra"
)

var stopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop a product",
	RunE: func(cmd *cobra.Command, args []string) error {
		return tool.Run(cmd, func(t *tool.Tool) error {
			return t.Stop()
		})
	},
}

func init() {
	rootCmd.AddCommand(stopCmd)
}
