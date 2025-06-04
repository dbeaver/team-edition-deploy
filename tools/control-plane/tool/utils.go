package tool

import (
	"archive/zip"
	"cbctl/lib"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

func downloadFile(downloadURL, saveAs string) error {
	if _, err := os.Stat(saveAs); err == nil {
		return fmt.Errorf("unable to download and save file as '%s': file exists", saveAs)
	}
	resp, err := http.Get(downloadURL)
	if err != nil {
		return lib.WrapError("unable to download a file", err)
	}
	defer lib.CloseOrWarn(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return errors.New("unable to download a file: GET request ended with code " + string(rune(resp.StatusCode)))
	}
	file, err := os.OpenFile(saveAs, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0700)
	if err != nil {
		return lib.WrapError("unable to download a file and save it: file wouldn't open for writing", err)
	}
	defer lib.CloseOrWarn(file)
	_, err = io.Copy(file, resp.Body)
	return err
}

func unzipFile(zipPath, destDir string) error {
	slog.Debug(fmt.Sprintf("unzipping file '%s' into '%s'", zipPath, destDir))
	zipReader, err := zip.OpenReader(zipPath)
	if err != nil {
		return err
	}
	defer lib.CloseOrWarn(zipReader)

	for _, file := range zipReader.File {
		filePath := filepath.Join(destDir, file.Name)
		if !strings.HasPrefix(filePath, filepath.Clean(destDir)+string(os.PathSeparator)) {
			return errors.New("illegal file path: " + file.Name)
		}
		if file.FileInfo().IsDir() {
			if err := os.MkdirAll(filePath, file.Mode()); err != nil {
				return err
			}
			continue
		}
		if err := os.MkdirAll(filepath.Dir(filePath), 0700); err != nil {
			return err
		}
		destFile, err := os.OpenFile(filePath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, file.Mode())
		if err != nil {
			return err
		}
		defer lib.CloseOrWarn(destFile)
		srcFile, err := file.Open()
		if err != nil {
			return err
		}
		defer lib.CloseOrWarn(srcFile)
		_, err = io.Copy(destFile, srcFile)
		if err != nil {
			return err
		}
	}

	return nil
}

func isPythonInstalledAndAtLeast(major, minor, micro int) bool {
	version, err := getPythonVersion()
	if err != nil {
		slog.Warn("unable to get Python version: " + err.Error())
		return false
	}
	isAtLeast, err := isSemanticVersionAtLeast(version, major, minor, micro)
	if err != nil {
		slog.Warn(fmt.Sprintf("unable to check if Python version is at least %d.%d.%d: %s",
			major, minor, micro, err.Error()))
		return false
	}
	return isAtLeast
}

func getPythonVersion() (string, error) {
	pythonCmd := exec.Command("python3", "--version")
	outputBytes, err := pythonCmd.Output()
	if err != nil {
		return "", err
	}
	// Version output is expected to be in the format "Python X.Y.Z"
	output, ok := strings.CutPrefix(string(outputBytes), "Python")
	if !ok {
		return "", errors.New("unexpected Python version format: " + output)
	}
	return strings.TrimSpace(output), nil
}

// FIXME: accept unsigned ints only
func isSemanticVersionAtLeast(version string, major, minor, micro int) (bool, error) {
	realMajorString, realMinorMicroString, ok := strings.Cut(version, ".")
	if !ok {
		return false, errors.New("unexpected version format: " + version)
	}
	realMajor, err := strconv.Atoi(realMajorString)
	if err != nil {
		return false, lib.WrapError(fmt.Sprintf("unable to parse the major version '%s'", realMajorString), err)
	}
	if realMajor < major {
		return false, nil
	}
	realMinorString, realMicroString, ok := strings.Cut(realMinorMicroString, ".")
	if !ok {
		return false, errors.New("unexpected version format: " + version)
	}
	realMinor, err := strconv.Atoi(realMinorString)
	if err != nil {
		return false, lib.WrapError(fmt.Sprintf("unable to parse the minor version '%s'", realMinorString), err)
	}
	if realMinor < minor {
		return false, nil
	}
	realMicro, err := strconv.Atoi(realMicroString)
	if err != nil {
		return false, lib.WrapError(fmt.Sprintf("unable to parse the micro version '%s'", realMinorString), err)
	}
	return realMicro >= micro, nil
}
