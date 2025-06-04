//go:build windows

package tool

import (
	"cbctl/lib"
	"log/slog"
	"os/exec"
)

func (t *Tool) ensureOSSpecificDependenciesAreInstalled() error {
	wslStatusCmd := exec.Command("wsl.exe", "--status")
	_, err := wslStatusCmd.Output()
	if err == nil {
		return nil
	}
	slog.Info("error caught while executing 'wsl.exe --status': " + err.Error())
	if exitErr, isExitErr := err.(*exec.ExitError); isExitErr {
		// stderr should contain the instructions on how to install WSL
		t.printlnBytes(exitErr.Stderr)
	}
	return lib.WrapError("WSL is not installed, but it's a hard requirement", err)
}
