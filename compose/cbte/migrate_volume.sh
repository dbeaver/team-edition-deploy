#!/bin/bash

SERVICES=(
  "cloudbeaver-dc:/opt/domain-controller/workspace /opt/domain-controller/conf/certificates /opt/domain-controller/conf/certificates/public"
  "cloudbeaver-rm:/opt/resource-manager/workspace"
  "cloudbeaver-tm:/opt/task-manager/workspace"
)
NEW_USER="dbeaver"
NEW_GROUP="dbeaver"

for SERVICE in "${SERVICES[@]}"; do
  SERVICE_NAME="${SERVICE%%:*}"
  VOLUME_PATHS="${SERVICE#*:}"

  CONTAINER_NAME=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.Names}}")
  if [ -z "$CONTAINER_NAME" ]; then
    echo "Error: No container found with the name '$SERVICE_NAME'"
    continue
  fi

  docker exec -it "$CONTAINER_NAME" bash -c "
    id '$NEW_USER' &>/dev/null || { useradd -m -s /bin/bash '$NEW_USER' && echo 'Created user: $NEW_USER'; }
    for VOLUME_PATH in $VOLUME_PATHS; do
      chown -R '$NEW_USER':'$NEW_GROUP' \"\$VOLUME_PATH\"
      find \"\$VOLUME_PATH\" -type d -exec chmod 775 {} +
      find \"\$VOLUME_PATH\" -type f -exec chmod 664 {} +
    done
  "

  echo "Volume migration completed successfully for container: $CONTAINER_NAME"
done
