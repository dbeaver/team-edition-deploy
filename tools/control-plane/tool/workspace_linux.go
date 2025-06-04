//go:build linux

package tool

import (
	"io/fs"
	"os"
	"path/filepath"

	"cbctl/lib"
)

func dbeaverDataParentLocation() (string, error) {
	if xdgDataHomePath, found := os.LookupEnv("XDG_DATA_HOME"); found && fs.ValidPath(xdgDataHomePath) {
		return xdgDataHomePath, nil
	}
	homePath, err := os.UserHomeDir()
	if err != nil {
		return "", lib.WrapError("unable to determine location of DBeaverData's parent directory", err)
	}
	return filepath.Join(homePath, ".local", "share"), nil
}
