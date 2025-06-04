package cmd

import (
	"cbctl/lib"
	"cbctl/tool"
	"github.com/spf13/cobra"
)

var configureDependenciesCmd = &cobra.Command{
	Use:   "dependencies",
	Short: "Configure dependencies for a product",
	RunE: func(cmd *cobra.Command, args []string) error {
		return tool.Run(cmd, func(t *tool.Tool) error {
			if err := t.EnsureDependenciesAreInstalled(); err != nil {
				return lib.WrapError("unable to ensure that all dependencies are installed", err)
			}
			return nil
		})
	},
}

func init() {
	configureCmd.AddCommand(configureDependenciesCmd)
}
