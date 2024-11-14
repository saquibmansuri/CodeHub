#!/bin/bash

# This script will be used in the ci/cd pipelines for fetching secrets from azure keyvault with desired prefix
# Note: the service principal should have access to the keyvault to fetch secrets
# The script can be executed like this - ./scriptname.sh "keyvaultname" "prefix" "filepath"


# Check if the correct number of arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <KeyVault Name> <Prefix> <Env File>"
    exit 1
fi

# Assign arguments to variables
KEYVAULT_NAME="$1"
PREFIX="$2"
ENV_FILE="$3"

# Clear the .env file if it exists
> "$ENV_FILE"

echo "Fetching all secrets with prefix '$PREFIX' from Key Vault"

# Fetch all secret names
all_secrets=$(az keyvault secret list --vault-name "$KEYVAULT_NAME" --query "[].name" -o tsv)

# Check if all_secrets is empty
if [ -z "$all_secrets" ]; then
    echo "No secrets found in Key Vault."
    exit 1
fi

# Loop through each secret name and process only those with the specified prefix
for secret_name in $all_secrets; do
    # Remove any carriage return characters
    secret_name=$(echo "$secret_name" | tr -d '\r')  # removing'\r as some windows shell add this in the end'

    if [[ "$secret_name" == "$PREFIX"* ]]; then
        echo "Processing secret: $secret_name"

        # Fetch the secret value
        secret_value=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "$secret_name" --query "value" -o tsv 2>&1)
        ret_val=$?

        # Check for errors in fetching the secret
        if [ $ret_val -ne 0 ]; then
            echo "Error fetching secret '$secret_name'"
            continue
        fi

        # Check if secret_value is empty
        if [ -z "$secret_value" ]; then
            echo "Warning: Secret '$secret_name' is empty."
            continue
        fi

        # Remove the prefix from the secret name and replace dashes with underscores
        trimmed_name=${secret_name#"$PREFIX"}
        formatted_name=${trimmed_name//-/_} # Replace dashes with underscores

        # Write to .env file
        echo "$formatted_name=\"$secret_value\"" >> "$ENV_FILE"
        echo "Success"
    fi
done

echo "Secrets have been fetched successfully"
