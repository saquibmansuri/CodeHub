#!/bin/bash

# This script can be used when in-built microsoft authentication for app service is enabled
# Usage: ./health_check.sh <health-check-url> [sleep_time]

# Check if URL parameter is provided
if [ -z "$1" ]; then
    echo "❌ Usage: ./health_check.sh <health-check-url> [sleep_time]"
    exit 1
fi

# THESE DETAILS SHOULD BE OF THE APP REGISTRATION THATS USED IN APP SERVICE AUTHENTICATION
CLIENT_ID=""
CLIENT_SECRET=""
TENANT_ID=""
APP_URL=$1
sleep_time=${2:-300}  # Default sleep time is 300 seconds if not provided

# Initial delay to allow the application to start
echo "⏳ Waiting for $sleep_time seconds to allow the app to start and stabilize..."
sleep $sleep_time

# Get access token using service principal
echo "🔑 Acquiring access token..."
TOKEN_RESPONSE=$(curl -s -X POST -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&resource=api://$CLIENT_ID" \
    https://login.microsoftonline.com/$TENANT_ID/oauth2/token)

# Check for errors in token response
if echo "$TOKEN_RESPONSE" | grep -q "error"; then
    echo "❌ Error getting token:"
    echo "$TOKEN_RESPONSE"
    exit 1
fi

# Extract access token
ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | sed 's/.*"access_token":"\([^"]*\)".*/\1/')

if [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ Failed to get access token"
    exit 1
fi

echo "✅ Access token acquired successfully"

# Retry logic
max_attempts=5
attempt=1

while [ $attempt -le $max_attempts ]
do
    echo "🔍 Attempt $attempt of $max_attempts: Checking health at $APP_URL..."
    response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $ACCESS_TOKEN" $APP_URL)

    if [ "$response" = "200" ]; then
        echo "✅ Health check passed! Status code: $response"
        exit 0
    else
        echo "❌ Health check failed! Status code: $response"
        if [ $attempt -eq $max_attempts ]; then
            echo "❌ Maximum attempts reached. Exiting with error..."
            exit 1
        fi
        echo "⏳ Waiting for 30 seconds before retrying..."
        sleep 30
    fi
    ((attempt++))
done 
