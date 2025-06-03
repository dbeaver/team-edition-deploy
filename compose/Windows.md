# Team Edition Server Installation on Windows

## Preparing your Windows environment

When running on Windows, you need to ensure that WSL is enabled. We also recommend using `podman` with `podman-compose`.

> Note:
If you run Windows on a virtual machine, please ensure that your host machine supports nested virtualization.

> Hint:
If using Azure VMs, ensure that
> - Your VM's `Security type` is set to `Standard`
> - Its size supports nested virtualization. `D2as_v6` is known to work.

Steps to prepare your Windows environment:

1. Ensure your machine has WSL installed by executing `wsl.exe --status` in PowerShell or Command Prompt. If WSL is not installed,
   follow the instructions that this command produces.
2. Ensure the dependencies are installed. We'll need `Git`, `podman`, and `podman-compose`.
   In turn, `podman-compose` requires Python 3.9 or later, and `pip`. Execute the following PowerShell **not as an administrator** to
   install everything you need:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop install git podman python
pip3 install podman-compose
```

3. Init and start a new podman machine:

```powershell
podman machine init --rootful dbeaver-team-edition-machine
podman machine start dbeaver-team-edition-machine
```

4. Determine the IP address of your podman machine:
    1. Execute `wsl.exe -d dbeaver-team-edition-machine`
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

5. Set up proxy for ports 80 and 443, and then open them. In PowerShell, execute

```powershell
netsh interface portproxy add v4tov4 listenport=80 listenaddress=0.0.0.0 connectport=80 connectaddress=172.31.142.32
netsh interface portproxy add v4tov4 listenport=443 listenaddress=0.0.0.0 connectport=43 connectaddress=172.31.142.32
New-NetFirewallRule -DisplayName "Allow Inbound TCP 80 for WSL" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80
New-NetFirewallRule -DisplayName "Allow Inbound TCP 443 for WSL" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 443
```

Change `172.31.142.32` to the IP address found in the previous step.

## Configuring and starting Team Edition cluster

1. Clone Git repository to your local machine by running the following command in your terminal:
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

## Stopping the cluster

```powershell
podman compose -f .\podman-compose.yml down
```
