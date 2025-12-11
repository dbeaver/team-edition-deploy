# Team Edition Server Installation on Windows

Use the **DBeaver Server Installer** to install dependencies, configure Team Edition, and run or stop the server on
Windows.

## Prepare your Windows environment

The installer checks your system and helps you install required components.

1. Download the [DBeaver Server Installer](https://github.com/dbeaver/dbeaver-server-installer/releases) executable and
   place it in any directory.

   If you prefer installing from source, install [Go](https://go.dev/dl/) (see the required version in the
   [`go.mod` file](https://github.com/dbeaver/dbeaver-server-installer/blob/devel/go.mod)) and run:

   ```
   go install github.com/dbeaver/dbeaver-server-installer@latest
   ```

2. Add the directory where you placed the executable to your system `PATH` environment variable.
   
3. Open a new terminal so the updated `PATH` is applied.

4. (Optional) Install shell completions.

   You can teach your shell to tab-complete the dbeaver-server-installer command and its subcommands. The exact steps
   depend on your shell.

   Run:

   ```
   dbeaver-server-installer completion --help
   ```

   Follow the instructions to install the completions for your shell.

5. Ensure WSL is installed.

   > Team Edition runs its containers under WSL, so WSL must be available before you continue.

   You can run:

   ```
   dbeaver-server-installer dependencies install
   ```

   This installs Git, Podman, and podman-compose, and also checks whether WSL is enabled.
   If WSL is missing, the installer will tell you and show guidance on how to install it.

   To install WSL manually, run:

   ```
   wsl.exe --install
   ```

6. Reboot your system after enabling WSL. The installer won’t proceed correctly until WSL is fully initialized.

## Configure and start Team Edition

1. Run:

   ```
   dbeaver-server-installer configure
   ```

   The tool creates the configuration directory and the `.env` file.
   Edit the `.env` file to set your domain, SSL options, and other properties. [Learn more](https://dbeaver.com/docs/team-edition/Team-Edition-deployment-with-Docker-Compose/#environment-file-configuration)

2. Start the server:

   ```
   dbeaver-server-installer start
   ```

   The tool deploys Team Edition, starts the containers, and opens the firewall ports needed for access.

   > **Note**: On Windows, `dbeaver-server-installer start` works only if PowerShell was launched with **Run as Administrator**.

3. After startup, you can access Team Edition at the url configured in your `.env` file.

## Stop Team Edition

To stop the server, run:

```
dbeaver-server-installer stop
```
