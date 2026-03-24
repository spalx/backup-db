#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[$(date)] $1"
}

if [ -z "${BKP_DB_NAME:-}" ]; then
  echo "BKP_DB_NAME not set and could not be inferred"
  exit 1
fi

PREFIX_PATH="s3://${BKP_S3_BUCKET}/${BKP_S3_PREFIX}/${BKP_DB_NAME}/"

log "Listing backups from $PREFIX_PATH"

aws s3 ls "$PREFIX_PATH" \
  --endpoint-url "$BKP_S3_ENDPOINT" \
  --human-readable \
  --summarize
