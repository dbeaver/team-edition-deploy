package tool

type dependency struct {
	executable  string
	displayName string
	// We assume that this link leads to a .zip file
	downloadURL string
	// Where in the downloaded and unpacked .zip file we can find the executable.
	// For example, if the executable is in 'usr/bin', then the slice will contain {"usr", "bin"}
	executableSubpath []string
	isSystemWideOk    bool
}

var dependencyGit = dependency{
	executable:        "git",
	displayName:       "Git",
	downloadURL:       "https://github.com/git-for-windows/git/releases/download/v2.49.0.windows.1/MinGit-2.49.0-busybox-64-bit.zip",
	executableSubpath: []string{"cmd"},
	isSystemWideOk:    true,
}

var dependencyPodman = dependency{
	executable:        "podman",
	displayName:       "Podman",
	downloadURL:       "https://github.com/containers/podman/releases/download/v5.5.0/podman-remote-release-windows_amd64.zip",
	executableSubpath: []string{"podman-5.5.0", "usr", "bin"},
	isSystemWideOk:    true,
}

var dependencyPython = dependency{
	executable:        "python.exe",
	displayName:       "Python 3",
	downloadURL:       "https://www.python.org/ftp/python/3.13.3/python-3.13.3-embed-amd64.zip",
	executableSubpath: []string{},
	isSystemWideOk:    false,
}
