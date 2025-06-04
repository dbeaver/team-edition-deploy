//go:build !windows

package tool

func (t *Tool) ensureOSSpecificDependenciesAreInstalled() error {
	return nil
}
