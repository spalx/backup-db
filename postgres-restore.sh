#!/usr/bin/env bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: postgres-restore.sh <backup-file> [table]"
  exit 1
fi

BACKUP_FILE="$1"
TABLE="${2:-}"  # optional table to restore

TMP_DIR="/tmp/bkp"
mkdir -p "$TMP_DIR"

S3_PATH="s3://${BKP_S3_BUCKET}/${BKP_S3_PREFIX}/${BKP_DB_NAME}/${BACKUP_FILE}"

echo "Downloading backup from:"
echo "$S3_PATH"

# Download backup from S3
aws s3 cp "$S3_PATH" "$TMP_DIR/backup.dump" \
  --endpoint-url "$BKP_S3_ENDPOINT"

# Build restore arguments
RESTORE_ARGS=(
  -d "$BKP_DB_NAME"
  --clean          # drops objects before restoring
  --no-owner       # avoid ownership issues
)

# If a specific table is provided
if [ -n "$TABLE" ]; then
  RESTORE_ARGS+=(--table "$TABLE")
fi

# Include the backup file
RESTORE_FILE="$TMP_DIR/backup.dump"

echo "Restoring PostgreSQL database..."

PGPASSWORD="$BKP_DB_PASSWORD" pg_restore \
  -h "$BKP_DB_HOST" \
  -p "$BKP_DB_PORT" \
  -U "$BKP_DB_USER" \
  "${RESTORE_ARGS[@]}" \
  "$RESTORE_FILE"

echo "Done."
