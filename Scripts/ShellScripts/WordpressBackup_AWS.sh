#!/bin/bash

# Set variables
TIMESTAMP=$(date +"%Y_%m_%d__%H_%M_%S")  # Year_Month_Date__Hour_Minute_Second format
BACKUP_DIR="/root/autobackupsite"
SITE_DIR="/var/www/html"
DB_NAME="database_name"
DB_USER="database_user"
DB_PASS="database_password"
DB_HOST="aws_rds_endpoint OR onhost mysql"
S3_BUCKET="s3://bucket-name"
SITE_BACKUP_FILE="site_files_backup_$TIMESTAMP.zip"
DB_BACKUP_FILE="site_db_backup_$TIMESTAMP.sql"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Function to handle errors
error_exit() {
    echo "Error: $1"
    exit 1
}

# Step 1: Zip website content
echo "Zipping website content..."
zip -r $BACKUP_DIR/$SITE_BACKUP_FILE $SITE_DIR || error_exit "Failed to zip website content."

# Step 2: Take MySQL dump of the database
echo "Taking database backup..."
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME > $BACKUP_DIR/$DB_BACKUP_FILE || error_exit "Failed to take database backup."

# Step 3: Upload backups to S3
echo "Uploading site backup to S3..."
aws s3 cp $BACKUP_DIR/$SITE_BACKUP_FILE $S3_BUCKET || error_exit "Failed to upload site backup to S3."

echo "Uploading database backup to S3..."
aws s3 cp $BACKUP_DIR/$DB_BACKUP_FILE $S3_BUCKET || error_exit "Failed to upload database backup to S3."

# Step 4: Clean up local backup files
echo "Cleaning up temporary backup files..."
rm -f $BACKUP_DIR/$SITE_BACKUP_FILE || error_exit "Failed to delete local site backup."
rm -f $BACKUP_DIR/$DB_BACKUP_FILE || error_exit "Failed to delete local database backup."

echo "Backup completed successfully."
