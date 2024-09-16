#!/bin/bash

# Variables
PROJECT_ID="myproject"
DATASET_ID="mydataset"  # Use only dataset name here
BUCKET_NAME="mybucket"
EXPORT_PATH="myfolder"

# Ensure the bucket is accessible
gsutil ls gs://${BUCKET_NAME}/ > /dev/null
if [ $? -ne 0 ]; then
    echo "Error: Cannot access the bucket ${BUCKET_NAME}. Check permissions."
    exit 1
fi

# Get list of all tables in the dataset
tables=$(bq ls --project_id=${PROJECT_ID} ${DATASET_ID} | awk 'NR>2 {print $1}')

# Check if tables are listed
if [ -z "$tables" ]; then
    echo "No tables found in dataset ${DATASET_ID}."
    exit 1
fi

# Print all table names
echo "Tables to be exported from dataset ${DATASET_ID}:"
echo "---------------------------------------------"
for table in $tables; do
    echo "- $table"
done
echo "---------------------------------------------"

# Loop through each table and export to CSV
for table in $tables; do
    echo "Starting export for table: $table ..."
    bq extract --destination_format=CSV \
    "${PROJECT_ID}:${DATASET_ID}.${table}" \
    "gs://${BUCKET_NAME}/${EXPORT_PATH}/${table}.csv"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to export table ${table}."
    else
        echo "Successfully exported table: $table"
    fi
    echo "---------------------------------------------"
done

echo "Export process completed."
