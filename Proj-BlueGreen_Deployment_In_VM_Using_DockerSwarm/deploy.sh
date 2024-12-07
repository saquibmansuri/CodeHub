#!/bin/bash

# Name of the stack
stack="dev"

# List of services and their health check URLs
services=("appfe" "appbe")

# In some cases localhost doesnot work, so try this in that case -  http://127.0.0.1:7001/api/HealthCheck/health
health_check_urls_blue=("http://localhost:5001/dashboard" "http://localhost:7001/api/HealthCheck/health")
health_check_urls_green=("http://localhost:5002/dashboard" "http://localhost:7002/api/HealthCheck/health")

# Declare the associative array for service statuses to ensure that the script manages associative arrays properly
# service_statuses stores the deployment status for each service
declare -A service_statuses

# Function to perform a health check on the deployed version
perform_health_check() {
  url=$1
  echo "Performing Health Check For Service-"$service" URL-"$url", For The New Version"
  for i in {1..5}; do
    status_code=$(curl --write-out "%{http_code}" --silent --output /dev/null "$url")
    if [ "$status_code" -eq 200 ]; then
      echo "Health Check Passed For Service-"$service" URL-"$url" As It Returned 200 Status Code, This Means New Version Is Stable"      return 0
    else
      echo "Health Check Failed For Service-"$service" URL-"$url", Retrying..."
      sleep 30
    fi
  done
  echo "Health Check Failed For Service-"$service" URL-"$url" After Maximum Number Of Retries. New Version Is Not Stable"
  return 1
}


# Determine the active version and deploy the other version for each service
for i in "${!services[@]}"; do
  service="${services[$i]}"
  echo "Checking The Active Version For The Service-"$service"..."

  blue_replicas=$(sudo docker service ls --filter name=${stack}_${service}_blue --format "{{.Replicas}}" | awk -F '/' '{print $1}')  green_replicas=$(sudo docker service ls --filter name=${stack}_${service}_green --format "{{.Replicas}}" | awk -F '/' '{print $1}')
  echo "Number Of Current Active Blue Replicas Of the Service-"$service" = $blue_replicas"
  echo "Number Of Current Active Green Replicas Of the Service-"$service" = $green_replicas"

  if [ $blue_replicas -gt 0 ]; then
    echo "Currently, Blue Version Of The Service-"$service" Is Active. So, Deploying Green Version With Updated Code/Docker Image."    export REPLICAS_BLUE=$blue_replicas
    export REPLICAS_GREEN=1
    new_version="green"
    old_version="blue"
    health_check_url="${health_check_urls_green[$i]}"
  elif [ $green_replicas -gt 0 ]; then
    echo "Currently, Green Version Of The Service-"$service" Is Active. So, Deploying Blue Version With Updated Code/Docker Image."    export REPLICAS_BLUE=1
    export REPLICAS_GREEN=$green_replicas
    new_version="blue"
    old_version="green"
    health_check_url="${health_check_urls_blue[$i]}"
  else
    echo "Currently, Neither Blue Nor Green OR Both Blue & Green Versions Of The Service-"$service" Is Active. So, Deploying Blue Version As Default With Updated Code/Docker Image."
    export REPLICAS_BLUE=1
    export REPLICAS_GREEN=0
    new_version="blue"
    old_version="green"
    health_check_url="${health_check_urls_blue[$i]}"
  fi

  # Scale up the new version while keeping the old version running
  echo "Scaling Up New Version-"$new_version" Of The Service-"$service" While Keeping The Old Version-"$old_version" Running For Now Until The New Version Stabilizes..."
  sudo docker service scale ${stack}_${service}_$new_version=1

  # Wait for the new version to start
  echo "Waiting For The New Version-"$new_version" Of The Service-"$service" To Start And Stabilize..."
  sleep 120

  # Perform health check for the service
  echo "Performing Health Check For The New Version-"$new_version" Of The Service-"$service"..."
  perform_health_check $health_check_url
  if [ $? -eq 0 ]; then
    echo "Deployment Succeeded Of The New Version-"$new_version" Of The Service-"$service". Now Stopping/Scaling Down The Old Version-"$old_version"."
    sudo docker service scale ${stack}_${service}_${old_version}=0
    service_statuses[$service]="NEW VERSION DEPLOYED SUCCESSFULLY !!!"
  else
    echo "Deployment Failed Of The New Version-"$new_version" Of The Service-"$service". Now Rolling Back To The Previous Version."    sudo docker service scale ${stack}_${service}_${new_version}=0
    #sudo docker service scale ${stack}_${service}_${old_version}=1 #No need to run old service as it is already running until new version passes the healthcheck
    service_statuses[$service]="NEW VERSION DEPLOYMENT FAILED !!! ROLLED BACK TO PREVIOUS STABLE VERSION"
  fi
done


# Print final status of each service
echo "Deployment Summary:"
for service in "${!service_statuses[@]}"; do
  echo "$service: ${service_statuses[$service]}"
done


# -- Webhook Notification Start --
# Prepare JSON payload for webhook notification
json_payload="{\"text\": \"Environment Name: $stack"
for service in "${!service_statuses[@]}"; do
  json_payload+="  ||  \\n$service: ${service_statuses[$service]}"
done
json_payload+="\"}"

# Send JSON payload to webhook
echo "Notifying On Teams"
curl -H "Content-Type: application/json" -d "$json_payload" <webhook_url>
# -- Webhook Notification End --
