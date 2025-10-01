$scriptDir = (Resolve-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition)).Path
$cbteDir = Split-Path $scriptDir -Parent
$envFile = Join-Path $cbteDir ".env"
if (-not (Test-Path $envFile)) {
    Write-Error "File '$envFile' does not exist. Create and first, then try again."
    exit 1
}

# Ensure Podman machine is up and running
$podmanMachineName = "dbeaver-team-edition"
# FIXME: the following commands print errors if vm already exists or running. It's ok for now, but it would be good to manage it gracefully
& podman machine init --rootful $podmanMachineName
& podman machine start $podmanMachineName

# TODO: Configure networking
Write-Host ""
Write-Host "The following the the eth0 interface info of a WSL machine that will run the product:"
Write-Host ""
wsl.exe -d "podman-$podmanMachineName" "--exec" "/bin/sh" "-c" "ip addr show eth0"
Write-Host ""

$env:PODMAN_COMPOSE_PROVIDER = "podman-compose"
$env:CONTAINER_CONNECTION = "$podmanMachineName-root"

$composeFile = Join-Path $cbteDir "podman-compose.yml"
& podman compose -f $composeFile up -d
