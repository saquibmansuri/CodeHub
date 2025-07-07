# HTTPS Setup Guide with sslip.io, Nginx, and Let's Encrypt

This guide explains how to set up HTTPS for any application running on a VM using sslip.io (free wildcard DNS), Nginx as reverse proxy, and Let's Encrypt for SSL certificates.
Official URL - https://sslip.io/

## Overview

**sslip.io** is a "magic DNS" service that automatically resolves domains containing IP addresses back to those IP addresses. This eliminates the need for DNS configuration while still allowing SSL certificates.

### How it works:
- Domain: `my-app.203-0-113-45.sslip.io`
- Automatically resolves to: `203.0.113.45`
- No DNS records needed!

## Prerequisites

- Ubuntu/Debian VM with public IP
- Application running on a specific port (e.g., 8080)
- Root or sudo access

## Step 1: Install Required Software

```bash
# Update system
sudo apt update

# Install nginx
sudo apt install nginx -y

# Install certbot for Let's Encrypt
sudo snap install --classic certbot

# Start and enable nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

## Step 2: Open Required Ports

Ensure these ports are open for outside access:
- **Port 80** (HTTP) - Required for Let's Encrypt certificate verification
- **Port 443** (HTTPS) - Required for HTTPS traffic

**Note:** Your application port (e.g., 8080) should only be accessible from localhost, not from outside. Nginx will proxy requests to it.

## Step 3: Find Your Public IP (If you dont know)

```bash
# Method 1: Check your public IP
curl ifconfig.me

# Method 2: Alternative
curl ipinfo.io/ip
```

**Example output:** `203.0.113.45`

## Step 4: Create Nginx Configuration

Replace `203-0-113-45` with your actual IP and `8080` with your app's port:

```bash
sudo nano /etc/nginx/sites-available/my-app
```

**Configuration content:**

```nginx
# Upstream configuration for your application
upstream my_app_server {
  server localhost:8080;
}

server {
  server_name my-app.203-0-113-45.sslip.io;
  
  location / {
    proxy_pass http://my_app_server;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

## Step 5: Enable the Site

```bash
# Enable the new site
sudo ln -s /etc/nginx/sites-available/my-app /etc/nginx/sites-enabled/

# Remove default site (optional)
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
sudo nginx -t

# If test passes, reload nginx
sudo systemctl reload nginx
```

## Step 6: Test HTTP Access From Inside the Server

```bash
# Test if your site is accessible via HTTP
curl -I http://my-app.203-0-113-45.sslip.io

# Should return headers from your application
```

## Step 7: Get SSL Certificate

```bash
sudo certbot --nginx --domain my-app.203-0-113-45.sslip.io --agree-tos --no-eff-email --non-interactive --redirect --email your-email@example.com
```

**Flag explanations:**
- `--nginx`: Use nginx plugin
- `--domain`: Your specific domain
- `--agree-tos`: Automatically agree to Let's Encrypt terms
- `--no-eff-email`: Don't share email with EFF
- `--non-interactive`: Run without prompting
- `--redirect`: Automatically redirect HTTP to HTTPS
- `--email`: Contact email for certificate notifications

## Step 8: Verify HTTPS Setup

```bash
# Test HTTPS access
curl -I https://my-app.203-0-113-45.sslip.io

# Or just open in the browser
https://my-app.203-0-113-45.sslip.io
```

# YOUR SETUP IS COMPLETE !!

## Bonus: Final Configuration Check

After certbot runs, your nginx config will be automatically updated to include SSL settings:

```nginx
upstream my_app_server {
  server localhost:8080;
}

server {
  server_name my-app.203-0-113-45.sslip.io;
  
  location / {
    proxy_pass http://my_app_server;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    client_max_body_size 200M;
  }

  listen 443 ssl; # managed by Certbot
  ssl_certificate /etc/letsencrypt/live/my-app.203-0-113-45.sslip.io/fullchain.pem; # managed by Certbot
  ssl_certificate_key /etc/letsencrypt/live/my-app.203-0-113-45.sslip.io/privkey.pem; # managed by Certbot
  include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
  ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
  if ($host = my-app.203-0-113-45.sslip.io) {
    return 301 https://$host$request_uri;
  } # managed by Certbot

  server_name my-app.203-0-113-45.sslip.io;
  listen 80;
  return 404; # managed by Certbot
}
```
