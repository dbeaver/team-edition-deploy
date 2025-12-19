# Team Edition Server Installation on Windows

## Automatic installation using DBeaver Server Installer

Use the **DBeaver Server Installer** to install dependencies, configure Team Edition, and run or stop the server on
Windows.

### Prepare your Windows environment

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

### Configure and start Team Edition

1. Run:

   ```
   dbeaver-server-installer configure
   ```

   The tool creates the configuration directory and the `.env` file.
   Edit the `.env` file to set your domain, SSL options, and other properties. [Learn more](https://dbeaver.com/docs/team-edition/Team-Edition-deployment-with-Docker-Compose/#environment-file-configuration)

   > You can start Team Edition without changing the `.env` file. The default values are enough for a basic setup.

2. Start the server:

   ```
   dbeaver-server-installer start
   ```

   The tool deploys Team Edition, starts the containers, and opens the firewall ports needed for access.

   > **Note**: On Windows, `dbeaver-server-installer start` works only if PowerShell was launched with **Run as Administrator**.

3. After startup, you can access Team Edition at the url configured in your `.env` file.

### Stop Team Edition

To stop the server, run:

```
dbeaver-server-installer stop
```

## Manual installation on Windows using WSL and podman

### Prepare your Windows environment

When running on Windows, you need to ensure that WSL is enabled. We also recommend using `podman` with `podman-compose`.

> Note:
If you run Windows on a virtual machine, please make sure that your host machine supports nested virtualization.

> Hint:
If using Azure VMs, ensure that
> - Your VM's `Security type` is set to `Standard`
> - Its size supports nested virtualization. `D2as_v6` is known to work.

Steps to prepare your Windows environment:

1. Ensure your machine has WSL installed by executing `wsl.exe --status` in PowerShell or Command Prompt. If WSL is not installed,
   follow one of these instructions:
   * [For Windows 10 or 11](https://learn.microsoft.com/en-us/windows/wsl/install)
   * [For any Windows Server](https://learn.microsoft.com/en-us/windows/wsl/install-on-server) 
2. Ensure the dependencies are installed.
   * Git: [Install Git for Windows](https://git-scm.com/downloads/win)
   * Podman: [Install Podman](https://github.com/containers/podman/releases)
   * `podman-compose`: `podman-compose` requires Python 3.9 or later, and `pip`.
      1. [Install Python for Windows](https://www.python.org/downloads/windows/). Note that if you choose a Windows embeddable package, you'll have to [install `pip` separately](https://pip.pypa.io/en/stable/installation/).
      2. [Install `podman-compose`](https://pypi.org/project/podman-compose/).

3. Init and start a new podman machine by executing the following in PowerShell or Command Prompt:

```powershell
podman machine init --rootful dbeaver-team-edition-machine
podman machine start dbeaver-team-edition-machine
```

4. [Determine the IP address of your podman machine](#how-to-determine-the-ip-address-of-the-wsl-machine).

5. Set up a proxy for ports 80 and 443, and then open them. In the PowerShell of the host machine, execute the following:

```powershell
netsh interface portproxy add v4tov4 listenport=80 listenaddress=0.0.0.0 connectport=80 connectaddress=CHANGEME
netsh interface portproxy add v4tov4 listenport=443 listenaddress=0.0.0.0 connectport=43 connectaddress=CHANGEME
New-NetFirewallRule -DisplayName "Allow Inbound TCP 80 for WSL" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80
New-NetFirewallRule -DisplayName "Allow Inbound TCP 443 for WSL" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 443
```

Change `CHANGEME` to the IP address found in the previous step.

### Configuring and starting the Team Edition cluster

1. Clone the Git repository to your local machine by running the following command in your terminal:
    ```powershell
    git clone https://github.com/dbeaver/team-edition-deploy.git
    ```

2. Navigate to `team-edition-deploy/compose/cbte`:

```powershell
cd .\team-edition-deploy\compose\cbte\
```

3. Create and edit the configuration file:
    - Copy `.env.example` to `.env`
    - Edit `.env` file to set configuration properties

4. [Configure SSL and domain](../SSL/README.md#ssl-certificate-configuration)

5. Start the cluster with:

```powershell
podman compose -f .\podman-compose.yml up -d
```

### Stopping the cluster

```powershell
podman compose -f .\podman-compose.yml down
```

### Misc

#### How to determine the IP address of the WSL machine
1. Execute `wsl.exe -d dbeaver-team-edition-machine` in PowerShell or Command Prompt:
2. Run `ip addr show eth0`. You'll see something like

```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:5b:bd:52 brd ff:ff:ff:ff:ff:ff
    inet 172.31.142.32/20 brd 172.31.143.255 scope global eth0
       valid_lft forever pref   erred_lft forever
    inet6 fe80::215:5dff:fe5b:bd52/64 scope link
       valid_lft forever preferred_lft forever
```

This means that the IP is `172.31.142.32`

You can exit the Linux shell by typing `exit`.
