#!/bin/bash

# syntax: ./<script_name>.sh "prefix" "destination_file"

# Variables with default values (can be overridden from outside)
PREFIX=${1:-"prefix-"}      # Prefix can be provided as the first argument
OUTPUT_FILE=${2:-"/home/ubuntu/myapp/destination.env"} # Output file path as second argument

# Clear the output file before appending new values
> "$OUTPUT_FILE"

# Fetch all parameters with the given prefix
aws ssm get-parameters-by-path \
  --path "/" \
  --with-decryption \
  --query "Parameters[?starts_with(Name, '${PREFIX}')].[Name,Value]" \
  --output text | while read -r name value; do
    # Print the name of the variable being fetched
    echo "Fetching: $name"
    
    # Remove prefix from the parameter name
    clean_name=$(echo "$name" | sed "s|^${PREFIX}||")
    
    # Append the variable to the .env file
    echo "${clean_name}=\"${value}\"" >> "$OUTPUT_FILE"
  done

echo "Environment variables written to $OUTPUT_FILE"
