if (-not (Get-Command git -ErrorAction Ignore)) {
    Write-Host "Git is not installed."
    if (Get-Command winget -ErrorAction Ignore) {
        Write-Host "Attempting to install Git using winget..."
        winget install --id Git.Git -e --source winget
    } else {
        Write-Host "winget is not available. Downloading Git for Windows installer..."
        $gitInstaller = "$env:TEMP\Git-Installer.exe"
        Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.51.0.windows.2/Git-2.51.0.2-64-bit.exe" -OutFile $gitInstaller
        Write-Host "Running Git installer silently..."
        # https://gitforwindows.org/silent-or-unattended-installation.html
        Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-" -Wait
        Write-Host "Git installation completed. Please restart your terminal if Git is still not recognized."
    }
} else {
    Write-Host "Git is installed."
}

$repoName = "team-edition-deploy"
$installPath = Join-Path $env:AppData "DBeaverData" | Join-Path -ChildPath "github" | Join-Path -ChildPath "dbeaver" | Join-Path -ChildPath $repoName
git clone https://github.com/dbeaver/$repoName.git --depth 1 $installPath
