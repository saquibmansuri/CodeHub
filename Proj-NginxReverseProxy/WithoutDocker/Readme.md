
# Nginx Reverse Proxy Setup on Host for Dockerized Applications

This guide provides detailed steps on setting up Nginx as a reverse proxy on the host machine for Dockerized applications, including automatic SSL configuration using Certbot.

Note: This guide assumes you are on linux (ubuntu preferable)

## Install Docker & Docker Compose 

```
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install docker-compose-plugin
```

## Step 1: Set Up Docker Services
First, define your Docker services using Docker Compose. Here's a basic setup for your frontend (`fe`) and backend (`be`) services:

```yaml
version: '3.8'

services:
  fe:
    image: <frontend-image>
    restart: unless-stopped
    ports:
      - 8080:80

  be:
    image: <backend-image>
    restart: unless-stopped
    ports:
      - 8081:80
```

Run the services with the following command:
```bash
docker compose up -d
```

## Step 2: Install and Configure Nginx
Install Nginx and set it to start automatically:
```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

Remove the default configuration file:
```bash
sudo rm /etc/nginx/sites-enabled/default
sudo rm /etc/nginx/sites-available/default
```

## Step 3: Create Nginx Configuration for Applications
Navigate to `/etc/nginx/sites-available` and create a new configuration file named `app`:
Note: You can create multiple files for different project/sites inside this directory

```bash
cd /etc/nginx/sites-available
sudo nano app
```

Paste the following configuration into the file:
Note: This initial file doesn't contain logic to redirect traffic from http to https and 443 block. No need to worry, when we will generate SSL certificates using certbot in the later steps, then certbot will add all that logic automatically. Just ensure this initial nginx conf file is there. 

```nginx
# Configuration for fe servers
upstream fe_servers {
  server localhost:8080;
}

# Configuration for be servers
upstream be_servers {
  server localhost:8081;
}

# Server block for fe server
server {
  listen 80;
  server_name fe.example.com;
  location / {
    proxy_pass http://fe_servers;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    client_max_body_size 200M;
  }
  # HSTS Setting
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}

# Server block for be server
server {
  listen 80;
  server_name be.example.com;
  location / {
    proxy_pass http://be_servers;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    client_max_body_size 200M;
  }
  # HSTS Setting
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
```

Create a symbolic link to enable the new configuration:
```bash
sudo ln -s /etc/nginx/sites-available/* /etc/nginx/sites-enabled/
```

## Step 4: Install Certbot and Configure SSL
Install Certbot and link it to make it accessible system-wide:
```bash
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

Run Certbot for each domain to obtain SSL certificates and configure Nginx automatically:
```bash
# Note - 'A' type DNS records should be pointing to correct subdomains defined in nginx config
sudo certbot --nginx --domain fe.example.com --agree-tos --no-eff-email --non-interactive --redirect --email hi@gmail.com
sudo certbot --nginx --domain be.example.com --agree-tos --no-eff-email --non-interactive --redirect --email hi@example.com
```

## Step 5: Reload Nginx
Finally, apply the changes by reloading Nginx:
```bash
# Before reloading please check updated nginx configuration - sudo nginx -t
sudo systemctl reload nginx
```

## Step 6: Setup cronjob asroot user
```bash
sudo crontab -e
# Paste this line in the last and save it
0 0 * * * certbot renew && systemctl reload nginx --quiet
```

## DONE
