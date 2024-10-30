@echo off
setlocal enabledelayedexpansion

set "NEW_USER=dbeaver"
set "NEW_GROUP=dbeaver"

call :process_container "cloudbeaver-dc" "/opt/domain-controller/workspace" "/opt/domain-controller/conf/certificates" "/opt/domain-controller/conf/certificates/public"
call :process_container "cloudbeaver-rm" "/opt/resource-manager/workspace"
call :process_container "cloudbeaver-tm" "/opt/task-manager/workspace"

endlocal
exit /b

:process_container
set "SERVICE_NAME=%~1"
shift
set "VOLUME_PATHS=%*"

for /f "delims=" %%i in ('docker ps --filter "name=%SERVICE_NAME%" --format "{{.Names}}"') do set "CONTAINER_NAME=%%i"

if "%CONTAINER_NAME%"=="" (
    echo Error: No container found with the name '%SERVICE_NAME%'
    exit /b
)

docker exec -it %CONTAINER_NAME% bash -c "id '%NEW_USER%' &>/dev/null || { useradd -m -s /bin/bash '%NEW_USER%' && echo 'Created user: %NEW_USER%'; }"

for %%P in (%VOLUME_PATHS%) do (
    docker exec -it %CONTAINER_NAME% bash -c "chown -R '%NEW_USER%':'%NEW_GROUP%' '%%P'"
    docker exec -it %CONTAINER_NAME% bash -c "find '%%P' -type d -exec chmod 775 {} +"
    docker exec -it %CONTAINER_NAME% bash -c "find '%%P' -type f -exec chmod 664 {} +"
)

echo Volume migration completed successfully for container: %CONTAINER_NAME%
exit /b
