. "$PSScriptRoot\common.ps1"
$envFile = Join-Path $cbteDir ".env"
if (-not (Test-Path $envFile)) {
    Write-Error "File '$envFile' does not exist. Create and first, then try again."
    exit 1
}

# Ensure Podman machine is up and running
# FIXME: the following commands print errors if vm already exists or running. It's ok for now, but it would be good to manage it gracefully
& podman machine init --rootful $podmanMachineName
& podman machine start $podmanMachineName

# TODO: Configure networking
Write-Host ""
Write-Host "The following the the eth0 interface info of a WSL machine that will run the product:"
Write-Host ""
wsl.exe -d "podman-$podmanMachineName" "--exec" "/bin/sh" "-c" "ip addr show eth0"
Write-Host ""

& podman compose -f $composeFile up -d
