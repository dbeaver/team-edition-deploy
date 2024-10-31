@echo off
setlocal enabledelayedexpansion

set NEW_USER=dbeaver
set NEW_GROUP=dbeaver

set "SERVICE_1=cloudbeaver-dc:/opt/domain-controller/workspace /opt/domain-controller/conf/certificates /opt/domain-controller/conf/certificates/public"
set "SERVICE_2=cloudbeaver-rm:/opt/resource-manager/workspace"
set "SERVICE_3=cloudbeaver-tm:/opt/task-manager/workspace"

for %%S in (SERVICE_1 SERVICE_2 SERVICE_3) do (
    call set "SERVICE=!%%S!"
    for /f "tokens=1 delims=:" %%A in ("!SERVICE!") do (
        set SERVICE_NAME=%%A
        echo Starting service '!SERVICE_NAME!'...
        docker compose up -d !SERVICE_NAME!
    )
)

for %%S in (SERVICE_1 SERVICE_2 SERVICE_3) do (
    call set "SERVICE=!%%S!"
    for /f "tokens=1,* delims=:" %%A in ("!SERVICE!") do (
        set SERVICE_NAME=%%A
        set VOLUME_PATHS=%%B

        set CONTAINER_NAME=
        :wait_for_container
        for /f "delims=" %%C in ('docker ps --filter "name=!SERVICE_NAME!" --format "{{.Names}}"') do set CONTAINER_NAME=%%C
        if "!CONTAINER_NAME!"=="" (
            echo Waiting for container associated with service '!SERVICE_NAME!' to start...
            timeout /t 1 >nul
            goto :wait_for_container
        )
        echo Container '!CONTAINER_NAME!' is up and running.

        docker exec -it !CONTAINER_NAME! bash -c "id '%NEW_USER%' &>/dev/null || { useradd -m -s /bin/bash '%NEW_USER%' && echo 'Created user: %NEW_USER%'; }"
        
        for %%P in (!VOLUME_PATHS!) do (
            docker exec -it !CONTAINER_NAME! chown -R %NEW_USER%:%NEW_GROUP% %%P
            docker exec -it !CONTAINER_NAME! bash -c "find '%%P' -type d -exec chmod 775 {} +"
            docker exec -it !CONTAINER_NAME! bash -c "find '%%P' -type f -exec chmod 664 {} +"
        )
        echo Volume migration completed successfully for container: !CONTAINER_NAME!
    )
)

for %%S in (SERVICE_1 SERVICE_2 SERVICE_3) do (
    call set "SERVICE=!%%S!"
    for /f "tokens=1 delims=:" %%A in ("!SERVICE!") do (
        set SERVICE_NAME=%%A
        echo Stopping service '!SERVICE_NAME!'...
        docker compose down !SERVICE_NAME!
    )
)
endlocal