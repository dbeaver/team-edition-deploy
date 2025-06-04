package tool

import (
	"cbctl/lib"
	"errors"
	"log/slog"
	"os/exec"
	"runtime"
)

type dependency struct {
	executable  string
	displayName string
	downloadURL string
}

type binaryInZipDependency struct {
	dependency
	// Where in the downloaded and unpacked .zip file we can find the executable.
	// For example, if the executable is in 'usr/bin', then the slice will contain {"usr", "bin"}
	executableSubpath []string
	isSystemWideOk    bool
}

var dependencyGit = binaryInZipDependency{
	dependency: dependency{
		executable:  "git",
		displayName: "Git",
		downloadURL: "https://github.com/git-for-windows/git/releases/download/v2.49.0.windows.1/MinGit-2.49.0-busybox-64-bit.zip",
	},
	executableSubpath: []string{"cmd"},
	isSystemWideOk:    true,
}

var dependencyPodman = binaryInZipDependency{
	dependency: dependency{
		executable:  "podman",
		displayName: "Podman",
		downloadURL: "https://github.com/containers/podman/releases/download/v5.5.0/podman-remote-release-windows_amd64.zip",
	},
	executableSubpath: []string{"podman-5.5.0", "usr", "bin"},
	isSystemWideOk:    true,
}

var dependencyPython = binaryInZipDependency{
	dependency: dependency{
		executable:  "python",
		displayName: "Python 3",
		downloadURL: "https://www.python.org/ftp/python/3.13.3/python-3.13.3-embed-amd64.zip",
	},
	executableSubpath: []string{},
	isSystemWideOk:    false,
}

var dependencyPip = dependency{
	executable:  "pip",
	displayName: "pip",
	downloadURL: "https://bootstrap-pypa-io.ingress.us-east-2.psfhosted.computer/pip/zipapp/pip-25.1.1.pyz",
}

func ensureOSSpecificDependenciesAreInstalled(printer Printer) error {
	if runtime.GOOS != osWindows {
		return nil
	}
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
