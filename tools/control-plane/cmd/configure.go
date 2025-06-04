package cmd

import (
	"cbctl/tool"
	"github.com/spf13/cobra"
)

var configureCmd = &cobra.Command{
	Use:   "configure",
	Short: "Configure a product or the host machine",
	RunE: func(cmd *cobra.Command, args []string) error {
		return tool.Run(cmd, func(t *tool.Tool) error {
			return t.Start()
		})
	},
}

func init() {
	rootCmd.AddCommand(configureCmd)
}
