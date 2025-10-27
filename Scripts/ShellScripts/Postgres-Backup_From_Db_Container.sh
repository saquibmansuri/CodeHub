#!/bin/bash
set -e
# ============================
# Docker PostgreSQL Backup to S3
# ============================

# Variables
CONTAINER_NAME="my_container_db"
DB_PORT=5432
DB_USER="admin"
DB_PASSWORD="password"
DB_NAME="mydb"
S3_BUCKET="s3://mybucket/prod/"
BACKUP_DIR="/home/ubuntu/backups"

# Generate timestamp
TIMESTAMP=$(date +"%Y_%m_%d__%H_%M_%S")
BACKUP_FILE="dbbackup_utc_${TIMESTAMP}.sql"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Create database backup from inside Docker container
echo "Starting database backup..."
docker exec -e PGPASSWORD=$DB_PASSWORD "$CONTAINER_NAME" pg_dump -U "$DB_USER" -d "$DB_NAME" -p "$DB_PORT" > "$BACKUP_PATH"

# Check if backup succeeded
if [ $? -eq 0 ]; then
    echo "Database backup successful: $BACKUP_FILE"
else
    echo "Database backup failed!" >&2
    exit 1
fi

# Upload to S3
echo "Uploading backup to S3..."
aws s3 cp "$BACKUP_PATH" "$S3_BUCKET"

# Verify upload success
if [ $? -eq 0 ]; then
    echo "Backup uploaded to S3: $S3_BUCKET$BACKUP_FILE"
else
    echo "Failed to upload backup to S3!" >&2
    exit 1
fi

# Delete local file
rm -f "$BACKUP_PATH"

if [ $? -eq 0 ]; then
    echo "Local backup file deleted. ✅ Script complete."
else
    echo "Failed to delete local backup file!" >&2
    exit 1
fi
