$cbteDir = Split-Path $PSScriptRoot -Parent
$composeFile = Join-Path $cbteDir "podman-compose.yml"
$podmanMachineName = "dbeaver-team-edition"

$env:PODMAN_COMPOSE_PROVIDER = "podman-compose"
$env:CONTAINER_CONNECTION = "$podmanMachineName-root"
