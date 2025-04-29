#!/usr/bin/env bash
set -e

DEPLOYMENT_ID=$(grep -A3 'variable "deployment_id"' variables.tf | grep 'default' | head -n1 | cut -d'"' -f2)
CLUSTER="DBeaverTeamEdition-$DEPLOYMENT_ID"
SERVICE="$DEPLOYMENT_ID-cloudbeaver-dc"
CONTAINER="$SERVICE"

LOCAL_DIR="build/cert"
TARGET_DIR="/opt/domain-controller/conf/certificates"

[[ -d "$LOCAL_DIR" ]] || { echo "ERROR: directory $LOCAL_DIR not found. Please put your certs in this path $PWD/$LOCAL_DIR and try again."; exit 1; }

TASK_ARN=$(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" \
            --query 'taskArns[0]' --output text)
[[ "$TASK_ARN" != "None" ]] || { echo "ERROR: no running task in $SERVICE"; exit 1; }

echo "INFO: using task $TASK_ARN"

TMP_TAR=$(mktemp)
tar -C "$LOCAL_DIR" -czf "$TMP_TAR" .
B64_PAYLOAD=$(base64 -w0 "$TMP_TAR")
rm -f "$TMP_TAR"

aws ecs execute-command \
  --cluster "$CLUSTER" \
  --task "$TASK_ARN" \
  --container "$CONTAINER" \
  --interactive \
  --command "bash -c '
    echo $B64_PAYLOAD | base64 -d | tar xz -C \"$TARGET_DIR\"
    if [ -d \"$TARGET_DIR/private\" ]; then
      mv \"$TARGET_DIR\"/private/* \"$TARGET_DIR\"/
      rmdir \"$TARGET_DIR/private\"
    fi
    chown -R 8978:8978 \"$TARGET_DIR\"
    chmod 600 \"$TARGET_DIR\"/*.key
    chmod 644 \"$TARGET_DIR\"/*.crt \"$TARGET_DIR\"/public/*.crt
    exit 0
  '"

echo "Certificates copied to $TARGET_DIR inside $CONTAINER"
