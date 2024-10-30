@echo off
setlocal

set SERVICES=(
  "cloudbeaver-dc:/opt/domain-controller/workspace /opt/domain-controller/conf/certificates /opt/domain-controller/conf/certificates/public"
  "cloudbeaver-rm:/opt/resource-manager/workspace"
  "cloudbeaver-tm:/opt/task-manager/workspace"
)
set NEW_USER=dbeaver
set NEW_GROUP=dbeaver

for %%S in (%SERVICES%) do (
  for /f "tokens=1,2 delims=:" %%A in ("%%S") do (
    set SERVICE_NAME=%%A
    set VOLUME_PATHS=%%B

    for /f "delims=" %%C in ('docker ps --filter "name=%SERVICE_NAME%" --format "{{.Names}}"') do set CONTAINER_NAME=%%C
    if "%CONTAINER_NAME%"=="" (
      echo Error: No container found with the name '%SERVICE_NAME%'
      goto :continue
    )

    docker exec -it %CONTAINER_NAME% bash -c ^
    "id '%NEW_USER%' &>/dev/null || { useradd -m -s /bin/bash '%NEW_USER%' && echo 'Created user: %NEW_USER%'; }; ^
    for VOLUME_PATH in %VOLUME_PATHS%; do ^
      chown -R '%NEW_USER%':'%NEW_GROUP%' \"$VOLUME_PATH\"; ^
      find \"$VOLUME_PATH\" -type d -exec chmod 775 {} +; ^
      find \"$VOLUME_PATH\" -type f -exec chmod 664 {} +; ^
    done"

    echo Volume migration completed successfully for container: %CONTAINER_NAME%
    :continue
  )
)

endlocal
