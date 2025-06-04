//go:build !windows

package tool

func ensureOSSpecificDependenciesAreInstalled(printer Printer) error {
	return nil
}
