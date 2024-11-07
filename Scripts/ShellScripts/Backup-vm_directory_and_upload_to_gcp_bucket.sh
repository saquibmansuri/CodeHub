#!/bin/bash

# Note: gsutil should be installed on the system and it should have permissions to copy objects to destination bucket
# Define the directories to be zipped and the destination bucket
# Add directories as needed, separated by spaces
DIRECTORIES_TO_BACKUP=(
    "/path/to/dir1"
    "/path/to/dir2"
    "/path/to/dir3"
)
DEST_BUCKET="gs://bucketname/vmfiles/"
ZIP_FILE="vm_files_backup_$(date +%Y_%m_%d).zip"

# Create the zip file with the specified directories
zip -r $ZIP_FILE "${DIRECTORIES_TO_BACKUP[@]}" 
if [ $? -eq 0 ]; then
    echo "Zip file created successfully."
else
    echo "Failed to create zip file."
    exit 1
fi

# Upload the zip file to the specified GCP bucket
/snap/bin/gsutil cp $ZIP_FILE $DEST_BUCKET
if [ $? -eq 0 ]; then
    echo "File uploaded successfully to $DEST_BUCKET."
else
    echo "Failed to upload file."
    rm $ZIP_FILE
    exit 1
fi

# Optional: Remove the zip file after upload to free up space
rm $ZIP_FILE
echo "Local backup file removed."

echo "Backup completed and uploaded to $DEST_BUCKET"
