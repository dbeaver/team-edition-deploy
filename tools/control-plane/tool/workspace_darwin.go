//go:build darwin

package tool

import (
	"os"
	"path/filepath"

	"cbctl/lib"
)

func dbeaverDataParentLocation() (string, error) {
	homePath, err := os.UserHomeDir()
	if err != nil {
		return "", lib.WrapError("unable to determine location of DBeaverData's parent directory", err)
	}
	return filepath.Join(homePath, "Library"), nil
}
