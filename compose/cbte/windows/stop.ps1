. "$PSScriptRoot\common.ps1"

& podman compose -f $composeFile down
