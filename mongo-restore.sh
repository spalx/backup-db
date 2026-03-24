#!/usr/bin/env bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: mongo-restore.sh <backup-file> [collection]"
  exit 1
fi

BACKUP_FILE="$1"
COLLECTION="${BKP_DB_NAME}.${2:-}"

TMP_DIR="/tmp/bkp"
mkdir -p "$TMP_DIR"

S3_PATH="s3://${BKP_S3_BUCKET}/${BKP_S3_PREFIX}/${BKP_DB_NAME}/${BACKUP_FILE}"

echo "Downloading backup from:"
echo "$S3_PATH"

# Download file
aws s3 cp "$S3_PATH" "$TMP_DIR/backup.gz" \
  --endpoint-url "$BKP_S3_ENDPOINT"

RESTORE_ARGS=(
  --archive="$TMP_DIR/backup.gz"
  --gzip
  --drop
)

if [ -n "$COLLECTION" ]; then
  RESTORE_ARGS+=(--nsInclude="$COLLECTION")
fi

if [ "$BKP_DB_TYPE" = "mongo" ]; then

  echo "Restoring..."

  if [ -n "${BKP_MONGO_URI:-}" ]; then

    mongorestore \
      --uri="$BKP_MONGO_URI" \
      "${RESTORE_ARGS[@]}"

  else

    mongorestore \
      --host "$BKP_DB_HOST" \
      --port "$BKP_DB_PORT" \
      --username "$BKP_DB_USER" \
      --password "$BKP_DB_PASSWORD" \
      "${RESTORE_ARGS[@]}"

  fi

else
  echo "Unsupported BKP_DB_TYPE"
  exit 1
fi

echo "Done."
