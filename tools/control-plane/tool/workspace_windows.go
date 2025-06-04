//go:build windows

package tool

import (
	"errors"
	"io/fs"
	"os"
)

func dbeaverDataParentLocation() (string, error) {
	if appDataPath, found := os.LookupEnv("APPDATA"); found && fs.ValidPath(appDataPath) {
		return appDataPath, nil
	}
	return "", errors.New("unable to determine location of DBeaverData's parent directory")
}
