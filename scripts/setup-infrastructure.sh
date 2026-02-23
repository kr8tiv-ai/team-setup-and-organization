#!/bin/bash

# KR8TIV AI Infrastructure Setup Script
# Installs monitoring, logging, and backup automation

set -e

echo "========================================="
echo "KR8TIV AI Infrastructure Setup"
echo "========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root or with sudo"
  exit 1
fi

echo "=== Step 1: Installing Uptime Kuma (Monitoring) ==="
docker run -d \
  --name uptime-kuma \
  --restart unless-stopped \
  -p 3001:3001 \
  -v uptime-kuma:/app/data \
  louislam/uptime-kuma:1

echo "✅ Uptime Kuma installed at http://YOUR_IP:3001"
echo ""

echo "=== Step 2: Installing Dozzle (Log Aggregation) ==="
docker run -d \
  --name dozzle \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p 9999:8080 \
  amir20/dozzle:latest

echo "✅ Dozzle installed at http://YOUR_IP:9999"
echo ""

echo "=== Step 3: Setting up automated backups ==="
mkdir -p /backups

# Copy backup script
cp scripts/backup-containers.sh /root/backup-containers.sh
chmod +x /root/backup-containers.sh

# Add to crontab (2 AM daily)
(crontab -l 2>/dev/null | grep -v backup-containers.sh; echo "0 2 * * * /root/backup-containers.sh >> /var/log/container-backup.log 2>&1") | crontab -

echo "✅ Daily backups configured (2 AM)"
echo ""

echo "=== Step 4: Enabling auto-restart on all containers ==="
# Get all running containers except monitoring tools
CONTAINERS=$(docker ps --format '{{.Names}}' | grep -v -E '(uptime-kuma|dozzle)')

for container in $CONTAINERS; do
  echo "  Setting restart policy for: $container"
  docker update --restart=unless-stopped $container
done

echo "✅ Auto-restart enabled on all containers"
echo ""

echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Visit http://YOUR_IP:3001 to configure Uptime Kuma"
echo "2. Visit http://YOUR_IP:9999 to view logs"
echo "3. Configure Telegram/Slack alerts in Uptime Kuma"
echo ""
echo "Backup location: /backups"
echo "Backup schedule: Daily at 2 AM"
echo ""
