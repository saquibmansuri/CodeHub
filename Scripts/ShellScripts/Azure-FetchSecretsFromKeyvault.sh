#!/bin/bash

# THIS SCRIPT IS USED TO FETCH ALL THE SECRETS WITH SOME PREFIX WITH THEIR VALUES FROM AZURE KEYVAULT
# Note: the service principal should have access to the keyvault to fetch secrets
# The script can be executed like this - ./scriptname.sh "keyvaultname" "prefix" "filepath"
# Example - ./script.sh "mykeyvault" "prod-" ".env"


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
    secret_name=$(echo "$secret_name" | tr -d '\r')  # removing '\r' as this creates issue in windows terminals

    if [[ "$secret_name" == "$PREFIX"* ]]; then
        echo "Processing secret: $secret_name"

        # Fetch the secret value
        secret_value=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "$secret_name" --query "value" -o tsv 2>&1)
        ret_val=$?

        # Check for errors in fetching the secret
        if [ $ret_val -ne 0 ]; then
            echo "Error fetching secret value - '$secret_name'"
            continue
        fi

        # Check if secret_value is empty
        if [ -z "$secret_value" ]; then
            echo "Warning: Secret '$secret_name' is empty."
            continue
        fi

        # Remove the prefix from the secret name and write to .env file
        trimmed_name=${secret_name#"$PREFIX"}
        echo "$trimmed_name=\"$secret_value\"" >> "$ENV_FILE"
        echo "Success"
    fi
done

echo "All secrets with '$PREFIX' have been fetched successfully"
