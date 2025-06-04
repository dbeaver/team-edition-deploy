package cmd

import (
	"cbctl/lib"
	"cbctl/tool"
	"fmt"
	"github.com/spf13/cobra"
	"io"
	"os"
	"path/filepath"
)

var configureProductCmd = &cobra.Command{
	Use:   "product",
	Short: "Configure a product",
	RunE: func(cmd *cobra.Command, args []string) error {
		return tool.Run(cmd, func(t *tool.Tool) error {
			repoPath, err := t.EnsureRepoIsCloned("team-edition-deploy")
			if err != nil {
				return err
			}
			composeDirPath := filepath.Join(repoPath, "compose")
			cbteDirPath := filepath.Join(composeDirPath, "cbte")
			envFilePath := filepath.Join(cbteDirPath, ".env")
			envFileExists, err := lib.FileExists(envFilePath)
			if err != nil {
				return lib.WrapError(fmt.Sprintf("unable to determine if the file '%s' exists: ", envFilePath), err)
			}
			if !envFileExists {
				err = copyFile(filepath.Join(cbteDirPath, ".env.example"), envFilePath)
				if err != nil {
					return lib.WrapError("unable to create .env file", err)
				}
			}
			cmd.Println(fmt.Sprintf("Open '%s' and edit it to configure the product", envFilePath))
			readmeFilePath := filepath.Join(composeDirPath, "README.md")
			cmd.Println(fmt.Sprintf("You can find more information about the product configuration in the '%s' file", readmeFilePath))
			return nil
		})
	},
}

func init() {
	configureCmd.AddCommand(configureProductCmd)
}

func copyFile(from, to string) error {
	srcFile, err := os.Open(from)
	if err != nil {
		return lib.WrapError(fmt.Sprintf("unable to open file '%s'", from), err)
	}
	defer lib.CloseOrWarn(srcFile)

	destFile, err := os.Create(to)
	if err != nil {
		return lib.WrapError(fmt.Sprintf("unable to create file '%s'", to), err)
	}
	defer lib.CloseOrWarn(destFile)

	_, err = io.Copy(destFile, srcFile)
	if err != nil {
		return lib.WrapError(fmt.Sprintf("unable to copy file from '%s' to '%s'", from, to), err)
	}

	return nil
}
