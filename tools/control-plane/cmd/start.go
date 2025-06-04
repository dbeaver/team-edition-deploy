package cmd

import (
	"cbctl/lib"
	"cbctl/tool"
	"errors"

	"github.com/spf13/cobra"
)

var startCmd = &cobra.Command{
	Use:   "start",
	Short: "Start a product",
	RunE: func(cmd *cobra.Command, args []string) error {
		t, err := tool.StartTool(cmd)
		if err != nil {
			return lib.WrapError("unable to initialize the tool", err)
		}
		defer lib.CloseOrWarn(&t)

		err = t.EnsureDependenciesAreInstalled()
		if err != nil {
			return lib.WrapError("unable to ensure that a dependency is installed or to install it", err)
		}

		err = t.EnsureRepoIsCloned("team-edition-deploy")
		if err != nil {
			return err
		}

		// TODO: configure the product if it wasn't configured yet

		return errors.New("product start is not fully implemented yet") // TODO
	},
}

func init() {
	rootCmd.AddCommand(startCmd)
}
