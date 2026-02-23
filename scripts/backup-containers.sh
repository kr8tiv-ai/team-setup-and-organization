#!/bin/bash

# KR8TIV AI - Container Backup Script
# Runs daily via cron to backup all agent data and databases
# Retention: 7 days

DATE=$(date +%Y%m%d)
BACKUP_DIR="/backups"

mkdir -p $BACKUP_DIR

echo "Starting backup at $(date)"

# Backup each agent's data volume
# Update this list with your agent names
AGENTS=("friday" "arsenal" "edith" "jocasta")

for agent in "${AGENTS[@]}"; do
  CONTAINER="openclaw-$agent"
  DATA_PATH="/docker/openclaw-$agent/data"
  
  if [ -d "$DATA_PATH" ]; then
    echo "Backing up $CONTAINER..."
    tar -czf $BACKUP_DIR/openclaw-$agent-$DATE.tar.gz \
      $DATA_PATH 2>/dev/null
  else
    echo "  Warning: $DATA_PATH not found, skipping"
  fi
done

# Backup Mission Control database
echo "Backing up Mission Control database..."
docker exec openclaw-mission-control-db-1 \
  pg_dump -U postgres mission_control \
  > $BACKUP_DIR/mission-control-db-$DATE.sql 2>/dev/null

# Keep last 7 days, delete older
echo "Cleaning up old backups..."
find $BACKUP_DIR -name "openclaw-*.tar.gz" -mtime +7 -delete
find $BACKUP_DIR -name "mission-control-db-*.sql" -mtime +7 -delete

echo "Backup completed at $(date)"
echo "Backup size:"
du -sh $BACKUP_DIR

# Optional: Upload to S3/B2/remote storage
# Uncomment and configure if needed:
# aws s3 sync $BACKUP_DIR s3://your-bucket/backups/
