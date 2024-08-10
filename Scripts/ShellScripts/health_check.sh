#!/bin/bash

# Usage: ./Devops/Scripts/health_check.sh <health-check-url>

health_check_url=$1
sleep_time=${2:-300} # Default sleep time is 300 seconds if not provided

# Initial delay to allow the application to start
echo "Waiting for $sleep_time seconds to allow the app to start and stabilize..."
sleep $sleep_time

# Retry logic
max_attempts=5
attempt=1
while [ $attempt -le $max_attempts ]
do
  echo "Attempt $attempt of $max_attempts: Checking health at $health_check_url..."
  if curl -f $health_check_url; then
    echo "Health check passed!"
    exit 0
  else
    echo "Health check failed!"
    if [ $attempt -eq $max_attempts ]; then
      echo "Maximum attempts reached. Exiting with error..."
      exit 1
    fi
    echo "Waiting for 30 seconds before retrying..."
    sleep 30
  fi
  ((attempt++))
done


##########################################################
# TO RUN THIS SCRIPT SIMPLY DO THIS
# sudo chmod +x health_check.sh
# health_check.sh <healthcheck_url> <sleep_time> 
