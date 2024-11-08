#!/bin/bash
source .env

PG_CONTAINER="postgres-upgrade-service"
POSTGRES_SERVICE="postgres"
PG_UPGRADE_IMAGE="dbeaver/cloudbeaver-postgres-upgrade:latest"
DATA_VOLUME="metadata_data"
TARGET_DATA_PATH="/var/lib/postgresql/data"

CONTAINER_ID=$(docker-compose ps -q $POSTGRES_SERVICE)

CONTAINER_STATUS=$(docker inspect -f '{{.State.Running}}' $CONTAINER_ID 2>/dev/null)

if [ "$CONTAINER_STATUS" == "true" ]; then
  echo "PostgreSQL container is running. Stopping the container..."
  docker-compose stop $POSTGRES_SERVICE
else
  echo "PostgreSQL container is already stopped."
fi

PROJECT_VOLUME="${COMPOSE_PROJECT_NAME}_${DATA_VOLUME}"

echo "data volume: $PROJECT_VOLUME"
echo "data mount: $TARGET_DATA_PATH"

docker pull $PG_UPGRADE_IMAGE

echo "Starting the pg-upgrade..."
docker run --rm \
  --name $PG_CONTAINER \
  -v ${PROJECT_VOLUME}:${TARGET_DATA_PATH} \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  $PG_UPGRADE_IMAGE

echo "Upgrade completed!"
