Write-Host "Checking WSL2 status..."
& wsl.exe --status > $null 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Output "WSL 2 is configured fine."
} else {
    Write-Error "You can install Windows Subsystem for Linux by running 'wsl.exe --install'." +
		" For more information please visit https://aka.ms/wslinstall"
    exit 1
}

$dependenciesInstallPath = Join-Path $env:AppData "DBeaverData" | Join-Path -ChildPath ".te-dependencies"

function Test-WingetAvailable {
    return [bool](Get-Command winget -ErrorAction Ignore)
}

if (-not (Get-Command podman -ErrorAction Ignore)) {
    Write-Host "Podman is not installed."
    if (Test-WingetAvailable) {
        Write-Host "Attempting to install Podman using winget..."
        winget install --id RedHat.Podman -e --source winget
    } else {
        Write-Host "winget is not available. Downloading and installing Podman..."
        $zipFile = "$env:TEMP\podman.zip"
        $podmanVersion = "5.6.1"
        Invoke-WebRequest -Uri "https://github.com/containers/podman/releases/download/v$podmanVersion/podman-remote-release-windows_amd64.zip" -OutFile $zipFile
        Expand-Archive -Path $zipFile -DestinationPath $dependenciesInstallPath -Force
        $pathToAdd = Join-Path $dependenciesInstallPath "podman-$podmanVersion" | Join-Path -ChildPath "usr" | Join-Path -ChildPath "bin"
        $env:Path = "$pathToAdd;$env:Path"
        [Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::User)
        Write-Host "Added Podman to user PATH: $pathToAdd"
    }
} else {
    Write-Host "Podman is installed."
}

& py.exe --version > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Python 3 is not installed."
    $pythonVersionToDownload = "3.13"
    if (Test-WingetAvailable) {
        Write-Host "Attempting to install Python 3 using winget..."
        winget install --id "Python.Python.$pythonVersionToDownload" -e --source winget
    } else {
        Write-Host "winget is not available. Downloading and installing Python 3..."
        $installerFile = "$env:TEMP\python3-installer.exe"
	    $pythonFullVersionToDownload = "$pythonVersionToDownload.7"
        Invoke-WebRequest -Uri "https://www.python.org/ftp/python/$pythonFullVersionToDownload/python-$pythonFullVersionToDownload-amd64.exe" -OutFile $installerFile
        Start-Process -FilePath $installerFile -ArgumentList "/quiet", "PrependPath=1" -Wait
    }
} else {
    Write-Host "Python 3 is installed."
}

& py.exe -m "pip" install pipx
& py.exe -m "pipx" ensurepath
& py.exe -m "pipx" install podman-compose

Write-Host "All dependencies are satisfied. Please restart your terminal if some of them are still not recognized."
