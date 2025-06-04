package cmd

import (
	"cbctl/app"
	"github.com/spf13/cobra"
)

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print " + app.AppName + " version",
	Run: func(cmd *cobra.Command, args []string) {
		cmd.Println(app.AppName + " " + app.AppVersion)
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
