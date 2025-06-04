package tool

import (
	"cbctl/lib"
	"errors"
	"log/slog"
	"os/exec"
)

func ensureOSSpecificDependenciesAreInstalled(printer Printer) error {
	printer.Println("Checking if WSL is installed...")
	wslStatusCmd := exec.Command("wsl.exe", "--status")
	_, err := wslStatusCmd.Output()
	if err == nil {
		printer.Println("WSL is installed")
		return nil
	}
	slog.Info("error caught while executing 'wsl.exe --status': " + err.Error())
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) {
		// stderr should contain the instructions on how to install WSL
		printer.Println(string(exitErr.Stderr))
	}
	return lib.WrapError("WSL is not installed, but it's a hard requirement", err)
}
