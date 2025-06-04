package cmd

import (
	"os"

	"cbctl/app"

	"github.com/spf13/cobra"
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   app.AppName,
	Short: "CloudBeaver control plane",
	// This long description is inspired by kubectl
	Long: app.AppName + " controls DBeaver Team Edition backend.",
	//Long: tool.AppName + " controls CloudBeaver Enterprise Edition, CloudBeaver AWS, and DBeaver Team Edition backends.", TODO
}

func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}
