package cmd

import (
	"cbctl/tool"
	"github.com/spf13/cobra"
)

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print " + tool.AppName + " version",
	Run: func(cmd *cobra.Command, args []string) {
		cmd.Println(tool.AppName + " " + tool.AppVersion)
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
