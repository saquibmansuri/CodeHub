#!/bin/bash

# Define the directory to be zipped and the destination bucket
# Note: the virtual machine should have access to read and write files to the gcp bucket 
SOURCE_DIR="/home/ubuntu"
DEST_BUCKET="gs://backups/vmfiles/prodvm/"
ZIP_FILE="prodvm_backup_$(date +%Y-%m-%d).zip"

# Navigate to the source directory
cd $SOURCE_DIR

# Create a zip file of all the contents in the source directory
zip -r $ZIP_FILE . 
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
