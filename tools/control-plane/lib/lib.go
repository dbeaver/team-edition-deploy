package lib

import (
	"fmt"
	"io"
	"log/slog"
	"runtime"
)

func WrapError(errorMessage string, original error) error {
	return fmt.Errorf("%s\n\tCaused by: %w", errorMessage, original)
}

func CloseOrWarn(closer io.Closer) {
	if err := closer.Close(); err != nil {
		slog.Warn("error while closing a Closer: " + err.Error())
	}
}

type Optional[T any] struct {
	Value     T
	IsPresent bool
}

func OptionalOf[T any](value T) Optional[T] {
	return Optional[T]{Value: value, IsPresent: true}
}

func IsWindows() bool {
	return runtime.GOOS == "windows"
}
