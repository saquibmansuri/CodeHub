#!/bin/bash

# Check if two arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <acr-name> <repository-name>"
    exit 1
fi

# Assign arguments to variables
ACR_NAME=$1
REPOSITORY_NAME=$2

# List all tags in the repository
echo "Fetching tags for repository '$REPOSITORY_NAME' in ACR '$ACR_NAME'..."

# Use process substitution to handle the output of the command
tags=$(az acr repository show-tags --name "$ACR_NAME" --repository "$REPOSITORY_NAME" --output tsv)

if [ -z "$tags" ]; then
    echo "No tags found for repository '$REPOSITORY_NAME'."
    exit 0
fi

# Loop through each tag and delete it
while IFS= read -r tag; do
    # Trim whitespace and newlines from tag
    tag=$(echo "$tag" | xargs)
    
    echo "Attempting to delete image with tag: '$tag'"
    
    # Attempt to delete the image by tag
    delete_output=$(az acr repository delete --name "$ACR_NAME" --image "$REPOSITORY_NAME:$tag" --yes 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "Successfully deleted tag: $tag"
    else
        echo "Failed to delete tag $tag. Error: $delete_output"
    fi
done <<< "$tags"

echo "Operation completed."
