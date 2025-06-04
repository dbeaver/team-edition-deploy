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
	return Tool{
		ws:      ws,
		printer: printer,
	}, nil
}

func (t *Tool) Close() error {
	return t.ws.Close()
}

func (t *Tool) EnsureDependenciesAreInstalled() error {
	if err := t.ensureOSSpecificDependenciesAreInstalled(); err != nil {
		return err
	}
	if _, err := t.ensureBinaryDependencyInstalled(&dependencyGit); err != nil {
		return err
	}
	if _, err := t.ensureBinaryDependencyInstalled(&dependencyPodman); err != nil {
		return err
	}

	if _, err := exec.LookPath("podman-compose"); err != nil {
		pythonPath, err := t.ensureBinaryDependencyInstalled(&dependencyPython)
		if err != nil {
			return err
		}
		scriptsDir := filepath.Join(pythonPath, "Scripts")
		if err = prependToPathVariable(scriptsDir); err != nil {
			return lib.WrapError(fmt.Sprintf("unable to prepend %s to PATH variable", scriptsDir), err)
		}
		pip, err := t.ensureDependencyInstalled(&dependencyPip)
		if err != nil {
			return err
		}
		t.printfln("Installing podman-compose...")
		outBytes, err := exec.Command(pythonPath, pip, "install", "podman-compose").Output()
		if err != nil {
			slog.Error(string(outBytes))
			return lib.WrapError("unable to install podman-compose", err)
		}
		t.println("Successfully installed podman-compose")
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

func (t *Tool) ensureBinaryDependencyInstalled(dependency *binaryInZipDependency) (string, error) {
	t.printfln("Ensuring %s is installed...", dependency.displayName)
	if dependency.isSystemWideOk {
		if path, err := exec.LookPath(dependency.executable); err == nil {
			t.println(dependency.displayName + " is found on the system. Reusing it")
			return path, nil
		}
	}

	// Maybe we installed it before?
	unzipPath, err := t.findUnzipPath(dependency.downloadURL)
	if err != nil {
		return "", err
	}
	path := make([]string, len(dependency.executableSubpath)+1)
	path[0] = unzipPath
	for i := range dependency.executableSubpath {
		path[i+1] = dependency.executableSubpath[i]
	}
	executableDirPath := filepath.Join(path...)
	executablePath := filepath.Join(executableDirPath, dependency.executable)
	if lib.IsWindows() {
		executablePath += ".exe"
	}
	if _, err := os.Stat(executablePath); err == nil {
		t.println(dependency.displayName + " is installed already")
		if err = prependToPathVariable(executableDirPath); err != nil {
			return "", lib.WrapError("unable to prepend "+executableDirPath+" to PATH variable", err)
		}
		return executablePath, nil
	}

	// No, we didn't. Let's download it then
	t.printfln("Downloading %s...", dependency.displayName)
	tmpDir, err := t.ws.TempDir()
	if err != nil {
		return "", lib.WrapError("unable to get temporary directory to download a file to", err)
	}
	zipFileName := filepath.Base(dependency.downloadURL)
	if zipFileName == "" || zipFileName == "." || zipFileName == "/" {
		return "", errors.New("something is wrong with the download URL: " + dependency.downloadURL)
	}
	zipFilePath := filepath.Join(tmpDir, zipFileName)
	if err := downloadFile(dependency.downloadURL, zipFilePath); err != nil {
		return "", lib.WrapError("unable to download "+zipFileName, err)
	}
	if err = unzipFile(zipFilePath, unzipPath); err != nil {
		return "", err
	}
	t.println("Successfully downloaded " + dependency.displayName)
	return executablePath, prependToPathVariable(executableDirPath)
}

func (t *Tool) ensureDependencyInstalled(dependency *dependency) (string, error) {
	t.printfln("Ensuring %s is installed...", dependency.displayName)
	filePath := filepath.Join(t.ws.DependenciesPath(), filepath.Base(dependency.downloadURL))
	exists, err := fileExists(filePath)
	if err != nil {
		return "", lib.WrapError(fmt.Sprintf("unable to figure out if %s is downloaded", dependency.displayName), err)
	}
	if exists {
		t.println(dependency.displayName + " is installed already")
		return filePath, nil
	}
	t.printfln("Downloading %s...", dependency.displayName)
	err = downloadFile(dependency.downloadURL, filePath)
	if err == nil {
		t.println("Successfully downloaded " + dependency.displayName)
	}
	return filePath, err
}

func prependToPathVariable(dir string) error {
	currentPath := os.Getenv("PATH")
	newPath := dir + string(os.PathListSeparator) + currentPath
	return os.Setenv("PATH", newPath)
}
