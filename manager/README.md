## Team Edition server manager

> **Note:** The Team Edition manager is available only on Linux.

`dbeaver-te` is a utility to manage a Team Edition server. Using this manager, you can start or stop the server, as well as update its version.

### Instalation

`dbeaver-te` will be installed automatically when using `install-manager.sh` script.

## How to use manager

Enter `dbeaver-te` or `dbeaver-te help` to see the help menu.

The `stop` and `start` commands will help you easily manage the state of the cluster, stop or start it.

### Configuration

To configure your server, you can enter the command `dbeaver-te configure`.
This will open the `.env` file, where you can change the parameters you want, then press `Ctrl+S` to save variables and `Ctrl+X` to exit the editor.


### Version update procedure

1. Connect to your server through the terminal.
2. Enter `dbeaver-te update list`
3. Choose the version you want to update.
4. Run this command: `dbeaver-te update %version%`
5. Restart the server: run `dbeaver-te stop`, then `dbeaver-te start`


### Backup and restore cluster

You can easily make backups of your cluster state, which will include service volumes, database dumps and internal certificates.

The command `createBackup` creates a backup of your cluster with internal certs and backup your internal database.

The command `restoreBackup` restores your cluster from backup, your cluster should already be running.
