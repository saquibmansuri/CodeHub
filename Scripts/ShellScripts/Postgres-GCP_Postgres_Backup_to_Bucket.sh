#!/bin/bash

# NOTE:
# pg client should exist on the machine where this script will execute, and version should match to that of cloud db server
# gsutil should be installed for copying files to storage bucket and it should have access to that bucket
# vm should also be able to access the secrets from secrets manager

# Define the destination bucket, change this according to your needs
DEST_BUCKET="gs://dbbackups/dev/"

# Check if SECRET_NAME is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <SECRET_NAME>"
    echo "Example: $0 Db_ConnectionString"  # this is the secret name in GCP secrets manager
    exit 1
fi

# Use the provided SECRET_NAME argument
SECRET_NAME=$1

# Fetch the connection string from Google Cloud Secret Manager
CONNECTION_STRING=$(gcloud secrets versions access latest --secret="$SECRET_NAME")
if [ $? -ne 0 ]; then
    echo "Failed to retrieve connection string from Secret Manager."
    exit 1
fi

# Parse the connection string into individual components
DB_HOST=$(echo $CONNECTION_STRING | sed -n 's/.*Host=\([^;]*\).*/\1/p')
DB_PORT=$(echo $CONNECTION_STRING | sed -n 's/.*Port=\([^;]*\).*/\1/p')
DB_NAME=$(echo $CONNECTION_STRING | sed -n 's/.*Database=\([^;]*\).*/\1/p')
DB_USER=$(echo $CONNECTION_STRING | sed -n 's/.*User ID=\([^;]*\).*/\1/p')
DB_PASSWORD=$(echo $CONNECTION_STRING | sed -n 's/.*Password=\([^;]*\).*/\1/p')

# Check if all values were extracted successfully
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "Error: Failed to parse all required values from the connection string."
    exit 1
fi

# Define the backup file name after DB_NAME is set
BACKUP_FILE="${DB_NAME}_dbbackup_$(date +%Y_%m_%d).sql"

# Export the password for pg_dump to use without prompt
export PGPASSWORD=$DB_PASSWORD

# Take a plain-text backup using pg_dump
pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -F p -b -v -f $BACKUP_FILE $DB_NAME
if [ $? -eq 0 ]; then
    echo "Database backup created successfully: $BACKUP_FILE"
else
    echo "Failed to create database backup."
    exit 1
fi

# Upload the backup file to the specified GCS bucket
gsutil cp $BACKUP_FILE $DEST_BUCKET
if [ $? -eq 0 ]; then
    echo "Backup file uploaded successfully to $DEST_BUCKET"
else
    echo "Failed to upload backup file to GCS."
    rm $BACKUP_FILE
    exit 1
fi

# Optional: Remove the backup file after upload to free up space
rm $BACKUP_FILE
echo "Local backup file removed."

echo "Database backup completed and uploaded to $DEST_BUCKET"
