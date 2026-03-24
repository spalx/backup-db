#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="/tmp/backup"

mkdir -p $BACKUP_DIR

log() {
  echo "[$(date)] $1"
}

retry() {
  n=0
  until [ "$n" -ge 5 ]
  do
    "$@" && break
    n=$((n+1))
    log "Retry $n..."
    sleep 5
  done

  if [ "$n" -ge 5 ]; then
    log "Command failed after retries"
    exit 1
  fi
}

log "Starting $BKP_DB_TYPE backup"

if [ "$BKP_DB_TYPE" = "postgres" ]; then

  FILE="$BACKUP_DIR/${BKP_DB_NAME}_${TIMESTAMP}.dump"
  EXTENSION="dump"

  export PGPASSWORD="$BKP_DB_PASSWORD"

  retry pg_dump \
    -h "$BKP_DB_HOST" \
    -p "$BKP_DB_PORT" \
    -U "$BKP_DB_USER" \
    -d "$BKP_DB_NAME" \
    -Fc \
    -Z 9 \
    -f "$FILE"

elif [ "$BKP_DB_TYPE" = "mongo" ]; then

  FILE="$BACKUP_DIR/${BKP_DB_NAME}_${TIMESTAMP}.gz"
  EXTENSION="gz"

  if [ -n "${BKP_MONGO_URI:-}" ]; then

    retry mongodump \
      --uri="$BKP_MONGO_URI" \
      --archive="$FILE" \
      --gzip

  else

    retry mongodump \
      --host "$BKP_DB_HOST" \
      --port "$BKP_DB_PORT" \
      --username "$BKP_DB_USER" \
      --password "$BKP_DB_PASSWORD" \
      --db "$BKP_DB_NAME" \
      --archive="$FILE" \
      --gzip

  fi

else
  log "Unsupported BKP_DB_TYPE"
  exit 1
fi

S3_PATH="s3://${BKP_S3_BUCKET}/${BKP_S3_PREFIX}/${BKP_DB_NAME}/${TIMESTAMP}.${EXTENSION}"

log "Uploading backup"

retry aws s3 cp "$FILE" "$S3_PATH" \
  --endpoint-url "$BKP_S3_ENDPOINT" \
  --no-progress

log "Upload complete"

rm -rf $BACKUP_DIR

# -----------------------
# RETENTION CLEANUP
# -----------------------

if [ -n "${BKP_RETENTION_DAYS:-}" ]; then

  log "Running retention cleanup (>${BKP_RETENTION_DAYS} days)"

  aws s3 ls "s3://${BKP_S3_BUCKET}/${BKP_S3_PREFIX}/${BKP_DB_NAME}/" \
    --endpoint-url "$BKP_S3_ENDPOINT" \
  | while read -r line; do

      createDate=$(echo $line | awk '{print $1" "$2}')
      fileName=$(echo $line | awk '{print $4}')

      if [[ -n "$fileName" ]]; then

        createDate=$(date -d "$createDate" +%s)
        olderThan=$(date -d "$BKP_RETENTION_DAYS days ago" +%s)

        if [[ $createDate -lt $olderThan ]]; then

          log "Deleting old backup: $fileName"

          aws s3 rm "s3://${BKP_S3_BUCKET}/${BKP_S3_PREFIX}/${BKP_DB_NAME}/$fileName" \
            --endpoint-url "$BKP_S3_ENDPOINT"

        fi
      fi
  done
fi

log "Backup job completed"
