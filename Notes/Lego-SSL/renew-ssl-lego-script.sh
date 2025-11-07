#!/bin/bash
set -e

# Run the Docker command and capture the output from both stdout and stderr
output=$(docker run --rm -v /root/ssl-cert-temp:/etc/lego --env HETZNER_API_KEY=abc goacme/lego --email 'me@gmail.com' --domains 'app.mycompany.com' --domains 'app2.mycompany.com' --accept-tos --path '/etc/lego' --dns 'hetzner' renew --days 4 --no-random-sleep 2>&1)

# Print the output for debugging purposes
echo "Docker command output:"
echo "$output"

# Check if the output contains the specific strings
if echo "$output" | grep -q "Server responded with a certificate"; then
    echo "Certificate renewed successfully, restarting nginx"
    docker compose -f /root/docker-compose.yml up -d --build --force-recreate --no-deps nginx
elif echo "$output" | grep -q "no renewal"; then
    echo "No renewal of certificate, thus not restarting nginx container"
else
    echo "Unexpected output of the renewal command"
fi
