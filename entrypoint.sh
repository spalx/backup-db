#!/usr/bin/env bash
set -e

if [ -z "$BKP_CRON_SCHEDULE" ]; then
  BKP_CRON_SCHEDULE="0 */12 * * *"
fi

echo "Using cron schedule: $BKP_CRON_SCHEDULE"

echo "$BKP_CRON_SCHEDULE /app/backup.sh" > /app/crontab

exec supercronic /app/crontab
