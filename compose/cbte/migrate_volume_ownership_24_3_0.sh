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
  if [ -z "$(docker ps --filter "name=$SERVICE_NAME" --format "{{.Names}}")" ]; then
    echo "Starting service '$SERVICE_NAME'..."
    docker compose up -d "$SERVICE_NAME"
  else
    echo "Service '$SERVICE_NAME' is already running."
  fi
done

for SERVICE in "${SERVICES[@]}"; do
  SERVICE_NAME="${SERVICE%%:*}"
  VOLUME_PATHS="${SERVICE#*:}"

  CONTAINER_NAME=""
  until [ -n "$CONTAINER_NAME" ]; do
    echo "Waiting for container associated with service '$SERVICE_NAME' to start..."
    CONTAINER_NAME=$(docker ps --filter "name=$SERVICE_NAME" --format "{{.Names}}")
    sleep 1
  done

  echo "Container '$CONTAINER_NAME' is up and running."

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

for SERVICE in "${SERVICES[@]}"; do
  SERVICE_NAME="${SERVICE%%:*}"
  if [ -n "$(docker ps --filter "name=$SERVICE_NAME" --format "{{.Names}}")" ]; then
    echo "Stopping service '$SERVICE_NAME'..."
    docker compose down "$SERVICE_NAME"
  else
    echo "Service '$SERVICE_NAME' is not running."
  fi
done