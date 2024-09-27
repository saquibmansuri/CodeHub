
# Docker Compose Setup with Nginx as a Reverse Proxy

This guide outlines the steps to configure Docker Compose to use Nginx as a reverse proxy for a frontend (`fe`) and backend (`be`) service setup, handling SSL certificates with Certbot on host.

## Install Docker & Docker Compose 
```
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install docker-compose-plugin
```

## Step 1: Set Up SSL Certificates with Certbot

Note: For this the A type dns record should exist before running the below commands

Generate SSL certificates for your domains using Certbot:

```bash
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot --nginx -d fe.example.com --agree-tos --no-eff-email --non-interactive --redirect --email example@gmail.com
sudo certbot --nginx -d be.example.com --agree-tos --no-eff-email --non-interactive --redirect --email example@gmail.com
```

## Step 2: Prepare the Nginx Configuration

Create your custom Nginx configuration to route requests to your services and enforce HTTPS security. Here's how you can set it up:

1. **Create the Nginx configuration directory**:
   ```bash
   mkdir -p nginx
   ```

2. **Create the Nginx configuration file (`nginx/default.conf`)**:
   Use your preferred text editor to create and modify the `default.conf` file in the `nginx` directory. Here's a sample configuration to handle both frontend and backend domains with HTTPS redirection:

   ```nginx
   # Redirect HTTP traffic to HTTPS for both fe.example.com and be.example.com
   server {
       listen 80;
       server_name fe.example.com be.example.com;

       location / {
           return 301 https://$host$request_uri;
       }
   }

   # HTTPS configuration for fe.example.com
   server {
       listen 443 ssl;
       server_name fe.example.com;

       ssl_certificate /etc/letsencrypt/live/fe.example.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/fe.example.com/privkey.pem;
       include /etc/letsencrypt/options-ssl-nginx.conf;
       ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

       location / {
           proxy_pass http://fe:80;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }

   # HTTPS configuration for be.example.com
   server {
       listen 443 ssl;
       server_name be.example.com;

       ssl_certificate /etc/letsencrypt/live/be.example.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/be.example.com/privkey.pem;
       include /etc/letsencrypt/options-ssl-nginx.conf;
       ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

       location / {
           proxy_pass http://be:80;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

## Step 3: Prepare Docker Compose Configuration

Update your `docker-compose.yml` file to include the custom configuration:

```yaml
version: '3.8'

services:
  fe:
    image: <frontend-image>
    restart: unless-stopped

  be:
    image: <backend-image>
    restart: unless-stopped

  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx:/etc/nginx/conf.d
      - /etc/letsencrypt:/etc/letsencrypt
    depends_on:
      - fe
      - be
    restart: unless-stopped
```

## Step 4: Run Docker Compose

Deploy your services using Docker Compose:

```bash
docker compose up -d
```

## Step 5: Manage Certificate Renewal

Setup cronjob to ensure that Certbot is configured to renew certificates automatically. Once certificates are renewed then the nginx container should be restarted

```bash
sudo crontab -e

# Paste this line at the bottom and save the it
0 0 * * * certbot renew && docker-compose -f docker-compose.yml up -d --build --force-recreate --no-deps nginx

```
