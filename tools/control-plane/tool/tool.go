package tool

import (
	"cbctl/lib"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

type Printer interface {
	Println(i ...any)
}

type Tool struct {
	ws      workspace
	printer Printer
}

func Run(printer Printer, f func(t *Tool) error) error {
	ws, err := initWorkspace()
	if err != nil {
		return lib.WrapError("unable to initialize workspace", err)
	}
	t := Tool{ws: ws, printer: printer}
	defer lib.CloseOrWarn(&t)
	return f(&t)
}

func (t *Tool) Close() error {
	return t.ws.Close()
}

func (t *Tool) Start() error {
	return errors.New("method is not implemented yet") // TODO: implement
}

func (t *Tool) Stop() error {
	return errors.New("method is not implemented yet") // TODO: implement
}

func (t *Tool) ConfigureHost() error {
	pathWithPodman, err := t.installationPathOfBinaryDependency(&dependencyPodman)
	if err != nil {
		return lib.WrapError("unable to get Podman installation path", err)
	}
	if err = prependToPathVariable(pathWithPodman); err != nil {
		return lib.WrapError("unable to prepend podman's directory to PATH variable", err)
	}

	inspectionResult, err := inspectPodmanMachine()
	if err != nil {
		return lib.WrapError("unable to inspect Podman machine", err)
	}
	switch inspectionResult {
	case vmExistsAndRunning:
		t.printer.Println("Podman machine is running")
	case vmDoesNotExist:
		t.printer.Println("Podman machine does not exist, creating it...")
		output, err := exec.Command("podman", "machine", "init", "--rootful", podmanMachineName).CombinedOutput()
		if err != nil {
			slog.Error(string(output))
			return lib.WrapError("unable to initialize Podman machine", err)
		}
		t.printer.Println("Podman machine created successfully")
		fallthrough
	case vmExistsAndNotRunning:
		t.printer.Println("Starting Podman machine...")
		output, err := exec.Command("podman", "machine", "start", podmanMachineName).CombinedOutput()
		if err != nil {
			slog.Error(string(output))
			return lib.WrapError("unable to start Podman machine", err)
		}
		t.printer.Println("Podman machine started successfully")
	default:
		// This should never happen, but let's handle it gracefully at least to make the compiler happy
		return errors.New("unexpected application error")
	}

	return nil
}

func (t *Tool) EnsureDependenciesAreInstalled() error {
	if err := ensureOSSpecificDependenciesAreInstalled(t.printer); err != nil {
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
		t.printer.Println("Ensuring podman-compose is installed...")
		outBytes, err := exec.Command(pythonPath, pip, "install", "podman-compose").Output()
		if err != nil {
			slog.Error(string(outBytes))
			return lib.WrapError("unable to install podman-compose", err)
		}
		t.printer.Println("podman-compose is installed")
	}

	return nil
}

func (t *Tool) EnsureRepoIsCloned(repoName string) (string, error) {
	repoURL := "https://github.com/dbeaver/" + repoName
	localRepoPath := filepath.Join(t.ws.Path(), repoName)
	localRepoStat, err := os.Stat(localRepoPath)
	if errors.Is(err, os.ErrNotExist) {
		execCmd := exec.Command("git", "clone", repoURL+".git", localRepoPath)
		outBytes, err := execCmd.Output()
		if err != nil {
			slog.Error(string(outBytes))
			return "", lib.WrapError("unable to clone repo "+repoURL, err)
		}
	} else if err != nil {
		return "", lib.WrapError(fmt.Sprintf("unable to detect if %s is cloned", repoURL), err)
	} else if !localRepoStat.IsDir() {
		return "", errors.New(localRepoPath + " is not a directory")
	} else {
		gitMetaStat, err := os.Stat(filepath.Join(localRepoPath, ".git"))
		if err != nil {
			return "", lib.WrapError(fmt.Sprintf("unable to detect if %s is a git repository", localRepoPath), err)
		}
		if !gitMetaStat.IsDir() {
			return "", errors.New(localRepoPath + " is not a git repository")
		}
	}
	return localRepoPath, nil
}

func (t *Tool) findUnzipPath(downloadURL string) (string, error) {
	zipFileName := filepath.Base(downloadURL)
	nameWithoutExt, ok := strings.CutSuffix(zipFileName, ".zip")
	if !ok {
		return "", fmt.Errorf("the URL '%s' doesn't end with '.zip'", downloadURL)
	}
	return filepath.Join(t.ws.DependenciesPath(), nameWithoutExt), nil
}

func (t *Tool) installationPathOfBinaryDependency(dependency *binaryInZipDependency) (string, error) {
	unzipPath, err := t.findUnzipPath(dependency.downloadURL)
	if err != nil {
		return "", err
	}
	path := make([]string, len(dependency.executableSubpath)+1)
	path[0] = unzipPath
	for i := range dependency.executableSubpath {
		path[i+1] = dependency.executableSubpath[i]
	}
	return filepath.Join(path...), nil
}

func (t *Tool) ensureBinaryDependencyInstalled(dependency *binaryInZipDependency) (string, error) {
	t.printer.Println(fmt.Sprintf("Ensuring %s is installed...", dependency.displayName))
	if dependency.isSystemWideOk {
		if path, err := exec.LookPath(dependency.executable); err == nil {
			t.printer.Println(dependency.displayName + " is found on the system. Reusing it")
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
		t.printer.Println(dependency.displayName + " is installed already")
		if err = prependToPathVariable(executableDirPath); err != nil {
			return "", lib.WrapError("unable to prepend "+executableDirPath+" to PATH variable", err)
		}
		return executablePath, nil
	}

	// No, we didn't. Let's download it then
	t.printer.Println(fmt.Sprintf("Downloading %s...", dependency.displayName))
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
	t.printer.Println("Successfully downloaded " + dependency.displayName)
	return executablePath, prependToPathVariable(executableDirPath)
}

func (t *Tool) ensureDependencyInstalled(dependency *dependency) (string, error) {
	t.printer.Println(fmt.Sprintf("Ensuring %s is installed...", dependency.displayName))
	filePath := filepath.Join(t.ws.DependenciesPath(), filepath.Base(dependency.downloadURL))
	exists, err := lib.FileExists(filePath)
	if err != nil {
		return "", lib.WrapError(fmt.Sprintf("unable to figure out if %s is downloaded", dependency.displayName), err)
	}
	if exists {
		t.printer.Println(dependency.displayName + " is installed already")
		return filePath, nil
	}
	t.printer.Println(fmt.Sprintf("Downloading %s...", dependency.displayName))
	err = downloadFile(dependency.downloadURL, filePath)
	if err == nil {
		t.printer.Println("Successfully downloaded " + dependency.displayName)
	}
	return filePath, err
}

func prependToPathVariable(dir string) error {
	currentPath := os.Getenv("PATH")
	newPath := dir + string(os.PathListSeparator) + currentPath
	return os.Setenv("PATH", newPath)
}

type podmanMachineInspectionResult int8

const (
	vmDoesNotExist podmanMachineInspectionResult = iota
	vmExistsAndNotRunning
	vmExistsAndRunning
	vmInUnknownState
)

func inspectPodmanMachine() (podmanMachineInspectionResult, error) {
	output, err := exec.Command("podman", "machine", "inspect", podmanMachineName).CombinedOutput()
	if strings.Contains(string(output), "VM does not exist") {
		if err != nil {
			slog.Info("error inspecting Podman machine", "error", err)
		}
		return vmDoesNotExist, nil
	} else if err != nil {
		return vmInUnknownState, err
	}
	trimmedResult := strings.TrimSpace(string(output))
	jsonResultString := strings.TrimLeftFunc(trimmedResult, func(r rune) bool {
		return r == '['
	})
	jsonResultString = strings.TrimRightFunc(jsonResultString, func(r rune) bool {
		return r == ']'
	})
	jsonResultString = strings.TrimSpace(jsonResultString)
	var resultMap map[string]json.RawMessage
	if err = json.Unmarshal([]byte(jsonResultString), &resultMap); err != nil {
		return vmInUnknownState, lib.WrapError("unable to parse Podman machine inspection result", err)
	}
	state, ok := resultMap["State"]
	if !ok {
		return vmInUnknownState, errors.New("unable to find 'State' in Podman machine inspection result")
	}
	switch string(state) {
	case "\"running\"":
		return vmExistsAndRunning, nil
	case "\"stopped\"":
		return vmExistsAndNotRunning, nil
	default:
		return vmInUnknownState, errors.New("unknown Podman machine state: " + string(state))
	}
}
