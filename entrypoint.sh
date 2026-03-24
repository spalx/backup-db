#!/usr/bin/env bash
set -e

if [[ "$BKP_CRON_ENABLED" != "true" && "$BKP_CRON_ENABLED" != "1" ]]; then
  echo "Cron is disabled (BKP_CRON_ENABLED=$BKP_CRON_ENABLED). Skipping setup."
  exec tail -f /dev/null
fi

if [ -z "$BKP_CRON_SCHEDULE" ]; then
  BKP_CRON_SCHEDULE="0 */12 * * *"
fi

echo "Using cron schedule: $BKP_CRON_SCHEDULE"

echo "$BKP_CRON_SCHEDULE /app/backup.sh" > /app/crontab

exec supercronic /app/crontab
