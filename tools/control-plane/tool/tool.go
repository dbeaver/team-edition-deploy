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
	pipInstallationScriptURL = "https://bootstrap.pypa.io/get-pip.py"
)

type stdOutErrPrinter interface {
	Println(i ...any)
	PrintErr(i ...any)
}

type Tool struct {
	ws              workspace
	printer         stdOutErrPrinter
	dependencyPaths map[string]string
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
	if err := t.ensureOSSpecificDependenciesAreInstalled(); err != nil {
		return err
	}
	if git, err := t.ensureInstalled(dependencyGit); err != nil {
		return err
	} else {
		t.dependencyPaths["git"] = git
	}
	if podman, err := t.ensureInstalled(dependencyPodman); err != nil {
		return err
	} else {
		t.dependencyPaths["podman"] = podman
	}

	if _, err := exec.LookPath("podman-compose"); err != nil {
		python, err := t.ensureInstalled(dependencyPython)
		if err != nil {
			return err
		}
		pipInstallScriptPath := filepath.Join(filepath.Dir(python), filepath.Base(pipInstallationScriptURL))
		err = downloadFile(pipInstallationScriptURL, pipInstallScriptPath)
		if err != nil {
			return err
		}
		installPipCmd := exec.Command(python, pipInstallScriptPath)
		_, err = installPipCmd.Output()
		if err != nil {
			return lib.WrapError("unable to install pip", err)
		}
	}

	return nil
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

func (t *Tool) printfln(format string, a ...any) {
	t.println(fmt.Sprintf(format, a...))
}

func (t *Tool) printlnBytes(bytes []byte) {
	t.println(string(bytes))
}

func (t *Tool) findUnzipPath(downloadURL string) (string, error) {
	zipFileName := filepath.Base(downloadURL)
	nameWithoutExt, ok := strings.CutSuffix(zipFileName, ".zip")
	if !ok {
		return "", fmt.Errorf("the URL '%s' doesn't end with '.zip'", downloadURL)
	}
	return filepath.Join(t.ws.DependenciesPath(), nameWithoutExt), nil
}

func (t *Tool) ensureInstalled(dep dependency) (string, error) {
	t.printfln("Ensuring %s is installed...", dep.displayName)
	if dep.isSystemWideOk {
		if path, err := exec.LookPath(dep.executable); err == nil {
			t.println(dep.displayName + " is found on the system. Reusing it")
			return path, nil
		}
	}

	// Maybe we installed it before?
	unzipPath, err := t.findUnzipPath(dep.downloadURL)
	if err != nil {
		return "", err
	}
	path := make([]string, len(dep.executableSubpath)+1)
	path[0] = unzipPath
	for i := range dep.executableSubpath {
		path[i+1] = dep.executableSubpath[i]
	}
	executablePath := filepath.Join(filepath.Join(path...), dep.executable)
	if lib.IsWindows() {
		executablePath += ".exe"
	}
	if _, err := os.Stat(executablePath); err == nil {
		t.println(dep.displayName + " is installed already")
		return executablePath, nil
	}

	// No, we didn't. Let's download it then
	t.printfln("Downloading %s...", dep.displayName)
	tmpDir, err := t.ws.TempDir()
	if err != nil {
		return "", lib.WrapError("unable to get temporary directory to download a file to", err)
	}
	zipFileName := filepath.Base(dep.downloadURL)
	if zipFileName == "" || zipFileName == "." || zipFileName == "/" {
		return "", errors.New("something is wrong with the download URL: " + dep.downloadURL)
	}
	zipFilePath := filepath.Join(tmpDir, zipFileName)
	if err := downloadFile(dep.downloadURL, zipFilePath); err != nil {
		return "", lib.WrapError("unable to download "+zipFileName, err)
	}
	if err = unzipFile(zipFilePath, unzipPath); err != nil {
		return "", err
	}
	return executablePath, nil
}
