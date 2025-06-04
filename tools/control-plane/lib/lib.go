package lib

import (
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"
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

func FileExists(path string) (bool, error) {
	_, err := os.Stat(path)
	if err == nil {
		return true, nil
	}
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	return false, err
}
