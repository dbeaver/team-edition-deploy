package tool

import (
	"cbctl/lib"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const (
	minGitURL             = "https://github.com/git-for-windows/git/releases/download/v2.49.0.windows.1/MinGit-2.49.0-busybox-64-bit.zip"
	podmanURL             = "https://github.com/containers/podman/releases/download/v5.5.0/podman-remote-release-windows_amd64.zip"
	pythonURL             = "https://www.python.org/ftp/python/3.13.3/python-3.13.3-embed-amd64.zip"
	pipInstallationScript = "https://bootstrap.pypa.io/get-pip.py"
)

type stdOutErrPrinter interface {
	Println(i ...any)
	PrintErr(i ...any)
}

type Tool struct {
	ws      workspace
	printer stdOutErrPrinter
}

func StartTool(printer stdOutErrPrinter) (Tool, error) {
	ws, err := initWorkspace()
	if err != nil {
		return Tool{}, lib.WrapError("unable to initialize workspace", err)
	}
	return Tool{ws: ws, printer: printer}, nil
}

func (t *Tool) Close() error {
	return t.ws.Close()
}

func (t *Tool) Workspace() *workspace {
	return &t.ws
}

func (t *Tool) EnsureDependenciesAreInstalled() error {
	err := t.ensureOSSpecificDependenciesAreInstalled()
	if err != nil {
		return err
	}
	_, err = t.ensureBinaryDependencyIsInstalled("git", "Git", minGitURL, "cmd")
	if err != nil {
		return err
	}
	_, err = t.ensureBinaryDependencyIsInstalled("podman", "Podman", podmanURL, "podman-5.5.0", "usr", "bin")
	if err != nil {
		return err
	}
	// if _, err := exec.LookPath("podman-compose"); err != nil {
	// 	if _, err := exec.LookPath("pip3"); err != nil || !isPythonInstalledAndAtLeast(3, 9, 0) {
	// 		t.println("Installing the required version of Python...")
	// 		dirWithPython, err := t.installDependency("python", "Python 3", pythonURL)
	// 		if err != nil {
	// 			return err
	// 		}
	// 		scriptPath := filepath.Join(dirWithPython, filepath.Base(pipInstallationScript))
	// 		err = downloadFile(pipInstallationScript, scriptPath)
	// 		if err != nil {
	// 			return err
	// 		}
	// 		ensurePipCmd := exec.Command("python", scriptPath)
	// 		out, err := ensurePipCmd.Output()
	// 		if err != nil {
	// 			return lib.WrapError("unable to install pip", err)
	// 		}
	// 		slog.Debug(string(out))
	// 	}
	// }

	return nil
}

func (t *Tool) ensureBinaryDependencyIsInstalled(executable, dependencyDisplayName, downloadURL string, executableSubpath ...string) (string, error) {
	t.println(fmt.Sprintf("ensuring %s is installed...", dependencyDisplayName))
	if _, err := exec.LookPath(executable); err == nil {
		return "", nil
	}
	return t.installDependency(executable, dependencyDisplayName, downloadURL, executableSubpath...)
}

func (t *Tool) installDependency(executable, dependencyDisplayName, downloadURL string, executableSubpath ...string) (string, error) {
	unzipPath, err := t.findUnzipPath(downloadURL)
	if err != nil {
		return "", err
	}
	path := make([]string, len(executableSubpath)+1)
	path[0] = unzipPath
	for i := 0; i < len(executableSubpath); i++ {
		path[i+1] = executableSubpath[i]
	}
	installDir := filepath.Join(path...)
	os.Setenv("PATH", installDir+string(os.PathListSeparator)+os.Getenv("PATH"))
	if path, err := exec.LookPath(executable); err == nil {
		slog.Debug(fmt.Sprintf("path to '%s' is '%s'", executable, path))
		return installDir, nil
	}
	t.println(dependencyDisplayName + " is not installed. Installing...")
	err = t.downloadAndUnzip(downloadURL, unzipPath)
	if err != nil {
		return "", lib.WrapError("unable to download "+dependencyDisplayName, err)
	}
	t.println(dependencyDisplayName + " has been installed.")
	return installDir, nil
}

func (t *Tool) EnsureRepoIsCloned(repoName string) error {
	repoURL := "https://github.com/dbeaver/" + repoName
	localRepoPath := filepath.Join(t.ws.Path(), repoName)
	localRepoStat, err := os.Stat(localRepoPath)
	if errors.Is(err, os.ErrNotExist) {
		execCmd := exec.Command("git", "clone", repoURL+".git", localRepoPath)
		outBytes, err := execCmd.Output()
		if err != nil {
			slog.Error(string(outBytes))
			return lib.WrapError("unable to clone repo "+repoURL, err)
		}
	} else if err != nil {
		return lib.WrapError(fmt.Sprintf("unable to detect if %s is cloned", repoURL), err)
	} else if !localRepoStat.IsDir() {
		return errors.New(localRepoPath + " is not a directory")
	} else {
		gitMetaStat, err := os.Stat(filepath.Join(localRepoPath, ".git"))
		if err != nil {
			return lib.WrapError(fmt.Sprintf("unable to detect if %s is a git repository", localRepoPath), err)
		}
		if !gitMetaStat.IsDir() {
			return errors.New(localRepoPath + " is not a git repository")
		}
	}
	return nil
}

func (t *Tool) println(s string) {
	t.printer.Println(s)
}

func (t *Tool) printlnBytes(bytes []byte) {
	t.println(string(bytes))
}

func (t *Tool) downloadAndUnzip(downloadURL, unzipPath string) error {
	tmpDir, err := t.ws.TempDir()
	if err != nil {
		return lib.WrapError("unable to get temporary directory to download a file to", err)
	}
	zipFileName := filepath.Base(downloadURL)
	if zipFileName == "" || zipFileName == "." || zipFileName == "/" {
		zipFileName = downloadURL
	}
	zipFilePath := filepath.Join(tmpDir, zipFileName)
	if err := downloadFile(downloadURL, zipFilePath); err != nil {
		return lib.WrapError("unable to download "+zipFileName, err)
	}
	return unzipFile(zipFilePath, unzipPath)
}

func (t *Tool) findUnzipPath(downloadURL string) (string, error) {
	zipFileName := filepath.Base(downloadURL)
	nameWithoutExt, ok := strings.CutSuffix(zipFileName, ".zip")
	if !ok {
		return "", fmt.Errorf("the URL '%s' doesn't end with '.zip'", downloadURL)
	}
	return filepath.Join(t.ws.DependenciesPath(), nameWithoutExt), nil
}
