package tool

import (
	"log/slog"
	"os"
	"path/filepath"
	"time"

	"cbctl/lib"
)

type workspace struct {
	path        string
	logFile     lib.Optional[*os.File]
	tempDirPath lib.Optional[string]
}

func (ws *workspace) Path() string {
	return ws.path
}

func initWorkspace() (ws workspace, err error) {
	// Create the workspace directory in DBeaverData
	dbeaverDataParentLoc, err := dbeaverDataParentLocation()
	if err != nil {
		return ws, lib.WrapError("unable to initialize workspace", err)
	}
	ws.path = filepath.Join(dbeaverDataParentLoc, "DBeaverData", AppName+"-workspace")
	err = os.MkdirAll(ws.path, 0700)
	if err != nil {
		return ws, lib.WrapError("unable to create logs folder", err)
	}

	// Start logging to file
	logsFolderPath := filepath.Join(ws.path, ".logs")
	err = os.MkdirAll(logsFolderPath, 0700)
	if err != nil {
		return ws, lib.WrapError("unable to create logs folder", err)
	}
	yearMonth := time.Now().UTC().Format("2006-01") // yyyy-MM format
	logFilePath := filepath.Join(logsFolderPath, yearMonth+".log")
	file, err := os.OpenFile(logFilePath, os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0600)
	if err != nil {
		return ws, lib.WrapError("unable to open log file", err)
	}
	ws.logFile = lib.OptionalOf(file)
	opts := slog.HandlerOptions{
		Level: slog.LevelDebug,
	}
	handler := slog.NewTextHandler(ws.logFile.Value, &opts)
	slog.SetDefault(slog.New(handler))
	return
}

func (ws *workspace) TempDir() (string, error) {
	if !ws.tempDirPath.IsPresent {
		tempDirPath, err := os.MkdirTemp(ws.path, ".temp-*")
		if err != nil {
			return "", err
		}
		ws.tempDirPath = lib.OptionalOf(tempDirPath)
	}
	return ws.tempDirPath.Value, nil
}

func (ws *workspace) Close() error {
	if ws.tempDirPath.IsPresent {
		if err := os.RemoveAll(ws.tempDirPath.Value); err != nil {
			slog.Warn("error while removing the contents of the temp directory: " + err.Error())
		}
	}
	if ws.logFile.IsPresent {
		if err := ws.logFile.Value.Close(); err != nil {
			return lib.WrapError("unable to close log file", err)
		}
	}
	return nil
}

func (ws *workspace) DependenciesPath() string {
	return filepath.Join(ws.path, ".dependencies")
}
