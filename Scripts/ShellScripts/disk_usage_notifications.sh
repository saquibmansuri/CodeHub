#!/bin/bash

# Configurable variables
THRESHOLD=90  # Set disk usage threshold (change as needed)
WEBHOOK_URL=""  # Replace with your Slack Webhook URL, steps given below
HOSTNAME=$(hostname)  # Get VM hostname
PUBLIC_IP=$(curl -s ifconfig.me)  # Get public IP
DISK_USAGE=$(df -h --output=pcent / | tail -n 1 | tr -d ' %')  # Fetch disk usage percentage

# Function to send Slack notification
send_slack_notification() {
    MESSAGE="⚠️  Disk Space Alert ⚠️  
    Disk usage has exceeded the threshold.
    *Hostname:* $HOSTNAME
    *Host Public IP:* $PUBLIC_IP   
    *Current Usage:* $DISK_USAGE%  
    *Threshold:* $THRESHOLD%"

    # Send the message to Slack
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$MESSAGE\"}" "$WEBHOOK_URL"
}

# Check if disk usage exceeds threshold
if [ "$DISK_USAGE" -ge "$THRESHOLD" ]; then
    send_slack_notification
fi


### Steps to get slack webhook url
# Go to api.slack.com/apps
# select the existing app or create a new one
# go to "Incoming Webhooks"
# Scroll down and click on "Add New Webhook to Workspace"
# Choose the channel where you want to post disk usage notifications and save/apply
# Copy the webhook URL
