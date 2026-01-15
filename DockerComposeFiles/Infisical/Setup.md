# 🚀 Setup Infisical Using Docker Compose

This guide explains how to self-host **Infisical** on a Linux VM using **Docker Compose**, with options for:

* Direct access via exposed port
* Reverse proxy using **Nginx** (with Cloudflare SSL)
* Free SSL using **Caddy** (without Cloudflare)

---

## ✅ Prerequisites

Before you begin, ensure the following are available:

* Linux-based VM (Ubuntu recommended)
* `docker` and `docker-compose` installed
* Domain name pointing to VM’s public IP (example: `infisical.company.xyz`)
* Firewall allows inbound traffic on:

  * **80 (HTTP)**
  * **443 (HTTPS)**

---

## 📦 Download Infisical Docker Compose Files

Follow the official Infisical documentation to download and configure Docker Compose and `.env` file:

👉 [https://infisical.com/docs/self-hosting/deployment-options/docker-compose](https://infisical.com/docs/self-hosting/deployment-options/docker-compose)

Clone the repo and follow the instructions to set up:

* `docker-compose.yml`
* `.env`

---

## 🔐 Configure Environment Variables

Update the following environment variables in the `.env` file:

```env
SITE_URL=https://infisical.company.xyz
ENCRYPTION_KEY=your-strong-random-key
AUTH_SECRET=your-strong-random-secret
POSTGRES_PASSWORD=strong-db-password
SMTP_HOST=smtp.example.com
SMTP_USERNAME=mailer@example.com
SMTP_PORT=587
SMTP_FROM_ADDRESS=no-reply@example.com
SMTP_FROM_NAME=Infisical
```

⚠️ **Important:**

* Use strong randomly generated secrets
* Never commit `.env` to Git

---

## ▶️ Start Infisical Services

From the directory containing `docker-compose.yml`:

```bash
docker compose up -d
```

Check containers:

```bash
docker compose ps
```

---

## 🌐 Access Infisical via Port Mapping

If your backend service exposes port `9090`, access Infisical at:

```
http://<VM-IP>:9090
```

or via domain if reverse proxy is configured:

```
https://infisical.company.xyz
```

On first login, you will be prompted to **create the first user**, which becomes:

* ✅ **Server Admin (highest privilege)**

---

## 🔁 Reverse Proxy Using Nginx (With Cloudflare SSL)

### 📁 File Location

Create config file:

```bash
sudo vim /etc/nginx/sites-available/infisical.company.xyz
```

### ⚙️ Nginx Configuration

```nginx
upstream infisical_servers {
    server localhost:9090;
}

server {
    server_name infisical.company.xyz;

    location / {
        proxy_pass http://infisical_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        client_max_body_size 200M;
    }
}
```

Enable site:

```bash
sudo ln -s /etc/nginx/sites-available/infisical.company.xyz /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

Cloudflare should handle SSL in this setup.

---

## 🔐 Setup MFA for Users

Enable Multi-Factor Authentication for better security:

👉 [https://infisical.com/docs/documentation/platform/mfa](https://infisical.com/docs/documentation/platform/mfa)

---

## 🔒 Free SSL Using Caddy (Without Cloudflare)

If you are **not using Cloudflare**, you can use **Caddy** to automatically manage SSL certificates.

### ➕ Add Caddy Service to Docker Compose

```yaml
  caddy:
    container_name: caddy
    image: caddy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./caddy/config:/config
      - ./caddy/data:/data
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile
```

### 📁 Create Required Folders

```bash
mkdir -p caddy/config caddy/data
```

### 📝 Create Caddyfile

```bash
vim caddy/Caddyfile
```

#### Caddyfile Content

```caddy
infisical.yourdomain.com {
    reverse_proxy backend:8080
}
```

🔁 Replace:

* `infisical.yourdomain.com` → your actual domain
* `backend:8080` → your Docker service name and port

---

## 🌍 DNS Configuration

Add DNS A record:

| Host                     | Type | Value        |
| ------------------------ | ---- | ------------ |
| infisical.yourdomain.com | A    | 52.33.45.123 |

Replace IP with your VM public IP.

---

## ▶️ Start Services with Caddy

```bash
docker compose up -d
```

Caddy will:

* Automatically request SSL certificates
* Renew them automatically

⚠️ **Important:** Port **80 must be publicly accessible** for HTTP challenge to work.

---

## ✅ Final Access URL

```
https://infisical.company.xyz
```

---

## 📌 Notes & Best Practices

* Always back up PostgreSQL volume
* Restrict admin access
* Enable MFA for all users
* Store `.env` securely
* Monitor disk usage (Docker can consume space quickly)

---

## 📚 References

* Infisical Docker Compose Docs:
  [https://infisical.com/docs/self-hosting/deployment-options/docker-compose](https://infisical.com/docs/self-hosting/deployment-options/docker-compose)

* Infisical MFA Docs:
  [https://infisical.com/docs/documentation/platform/mfa](https://infisical.com/docs/documentation/platform/mfa)
