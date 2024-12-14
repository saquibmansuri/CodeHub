#!/bin/bash

# Check if sufficient arguments are provided
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 HOST DB_NAME USERNAME PASSWORD GPG_RECIPIENT BUCKET"
    exit 1
fi

# Assign variables from script arguments
HOST=$1
DB_NAME=$2
USERNAME=$3
export PASSWORD=$4
GPG_RECIPIENT=$5
BUCKET=$6

# File names
BACKUP_FILE="${DB_NAME}_backup_$(date +%Y-%m-%d___%H-%M-%S).sql"
ENCRYPTED_FILE="${BACKUP_FILE}.gpg"

echo "Starting backup of database $DB_NAME"
# Backup PostgreSQL
pg_dump -h $HOST -U $USERNAME -d $DB_NAME -f $BACKUP_FILE

# Check if pg_dump was successful
if [ $? -eq 0 ]; then
    echo "Database backup successful, file created: $BACKUP_FILE"
else
    echo "Database backup failed"
    exit 1
fi

echo "Encrypting the backup file..."
# Encrypt the backup
gpg --encrypt -r $GPG_RECIPIENT -o $ENCRYPTED_FILE $BACKUP_FILE

# Check if encryption was successful
if [ $? -eq 0 ]; then
    echo "Encryption successful, file created: $ENCRYPTED_FILE"
else
    echo "Encryption failed"
    rm $BACKUP_FILE
    exit 1
fi

echo "Uploading the encrypted backup to S3..."
# Upload to S3
aws s3 cp $ENCRYPTED_FILE $BUCKET

# Check if upload was successful
if [ $? -eq 0 ]; then
    echo "Upload successful"
else
    echo "Upload failed"
    exit 1
fi

# Clean up: remove the local backup files
echo "Cleaning up local files..."
rm $BACKUP_FILE $ENCRYPTED_FILE

echo "Backup process completed successfully."
