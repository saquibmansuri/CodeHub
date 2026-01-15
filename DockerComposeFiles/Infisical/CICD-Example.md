# 🔐 Infisical Implementation Guide for .NET Web API

This guide explains how to integrate **Infisical** with a **.NET Web API** application for:

* Local development
* Visual Studio / Rider debugging
* CI/CD using GitHub Actions

---

## ✅ 1. Prerequisites

Ensure the following are available:

* .NET SDK **7+** installed
* A running **.NET Web API** project
* Infisical account → [https://infisical.com](https://infisical.com)
* Infisical CLI installed

### 📦 Install Infisical CLI

```bash
npm install -g infisical
```

Verify:

```bash
infisical --version
```

---

## 🧩 2. Setup Infisical Project

### 2.1 Login to Infisical

```bash
infisical login
```

### 2.2 Create Workspace & Project

1. Open Infisical Dashboard
2. Create or select a **Workspace**
3. Create a **Project** (example: backend-api)
4. Add secrets under environments:

   * `dev`
   * `staging`
   * `prod`

### 2.3 Add Secrets

Examples:

* `DB_CONNECTION_STRING`
* `JWT_SECRET`
* `SMTP_PASSWORD`
* `THIRD_PARTY_API_KEY`

Store secrets under proper **paths** if required (e.g., `/backend-secrets`).

---

## 🔗 3. Connect .NET Project with Infisical

There are multiple supported ways.

---

### ✅ Option A: Run via Infisical CLI (Recommended for Local Dev)

```bash
infisical run -- dotnet run
```

✔ Injects all secrets as environment variables at runtime.

Access them using:

```csharp
Environment.GetEnvironmentVariable("DB_CONNECTION_STRING");
```

---

### ✅ Option B: Use Infisical .NET SDK

#### Install Package

```bash
dotnet add package Infisical
```

#### Example (`Program.cs`)

```csharp
using Infisical.Sdk;

var builder = WebApplication.CreateBuilder(args);

var client = new InfisicalClient(new InfisicalClientOptions
{
    Token = Environment.GetEnvironmentVariable("INFISICAL_TOKEN") ?? ""
});

var dbConnectionString = await client.GetSecret("DB_CONNECTION_STRING", "dev");
builder.Configuration["ConnectionStrings:DefaultConnection"] = dbConnectionString;

var app = builder.Build();
```

⚠️ Token must be set securely using environment variable or Infisical machine identity.

---

### ✅ Option C: Run via Visual Studio / Rider (Debug Profile)

To avoid running CLI manually, configure **launchSettings.json**.

### 📄 `Properties/launchSettings.json`

```json
"profiles": {
  "COMPANY.CustomerSuccess.Platform": {
    "commandName": "Executable",
    "executablePath": "infisical",
    "commandLineArgs": "run --env=local --path=/backend-secrets -- dotnet run --project <PATH_TO_.CSPROJ>",
    "launchBrowser": true,
    "applicationUrl": "https://localhost:44347",
    "environmentVariables": {
      "ASPNETCORE_ENVIRONMENT": "Development"
    }
  }
}
```

▶ Now in Visual Studio or Rider:

* Select this profile
* Press **F5** to run with Infisical secrets

---

# 🚀 Implement Infisical in CI/CD (GitHub Actions)

Secrets are pulled dynamically from Infisical during deployment.

---

## 📄 GitHub Actions Workflow

### File: `.github/workflows/backend-deploy.yml`

```yaml
name: Backend Deployment

on:
  push:
    branches:
      - dev
      - prod

jobs:
  deploy-backend:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Determine Deployment Path
        id: set-vars
        run: |
          if [[ "${GITHUB_REF##*/}" == "prod" ]]; then
            echo "env_path=/root/_app_server/production/backend" >> $GITHUB_OUTPUT
          else
            echo "env_path=/root/_app_server/development/backend" >> $GITHUB_OUTPUT
          fi

      # ==============================
      # Load VPS / Infra Level Secrets
      # ==============================
      - name: Load VPS Environment Variables
        uses: infisical/secrets-action@v1.0.12
        with:
          method: universal                                   # Fetch all secrets universally
          client-id: ${{ secrets.INFISICAL_CLIENT_ID }}       # Infisical app client ID
          client-secret: ${{ secrets.INFISICAL_CLIENT_SECRET }} # Infisical app client secret
          domain: ${{ secrets.INFISICAL_SERVER_DOMAIN }}       # Infisical workspace URL
          project-slug: ${{ secrets.INFISICAL_COMPANY_VPS_SLUG }} # VPS / Infra project slug
          env-slug: global                                     # Use 'global' for shared VPS secrets

      # ==============================
      # Load Application Secrets
      # ==============================
      - name: Load Application Environment Variables
        uses: infisical/secrets-action@v1.0.12
        with:
          method: universal
          client-id: ${{ secrets.INFISICAL_CLIENT_ID }}
          client-secret: ${{ secrets.INFISICAL_CLIENT_SECRET }}
          domain: ${{ secrets.INFISICAL_SERVER_DOMAIN }}
          project-slug: ${{ secrets.INFISICAL_APP_PROJECT_SLUG }}
          secret-path: /backend-secrets                        # Path for backend environment variables
          env-slug: ${{ github.ref_name }}                     # Automatically picks the branch name (dev/prod)
          export-type: "file"                                 # Export all variables into a .env file

      # ==============================
      # Deploy Files to VPS
      # ==============================
      - name: Deploy Files to Server using rsync
        uses: burnett01/rsync-deployments@7.0.2
        with:
          switches: -avzr --delete
          path: .
          remote_path: ${{ steps.set-vars.outputs.env_path }}
          remote_host: ${{ env.SSH_HOST }}
          remote_user: ${{ env.SSH_USERNAME }}
          remote_key: ${{ env.SSH_PRIVATE_KEY }}

      # ==============================
      # Build & Restart Docker Service
      # ==============================
      - name: Build and Deploy Backend Container
        uses: appleboy/ssh-action@master
        with:
          host: ${{ env.SSH_HOST }}
          username: ${{ env.SSH_USERNAME }}
          key: ${{ env.SSH_PRIVATE_KEY }}
          command_timeout: 30m
          script: |
            cd ${{ steps.set-vars.outputs.env_path }}
            cd ..
            docker compose up -d --build --force-recreate --no-deps app-backend
```

---

## 🔑 Require

Configure these in GitHub → Repository → Settings → Secrets → Actions

### 🔐 Infisical Auth

* `INFISICAL_CLIENT_ID`
* `INFISICAL_CLIENT_SECRET`
* `INFISICAL_SERVER_DOMAIN`
* `INFISICAL_COMPANY_VPS_SLUG`
* `INFISICAL_APP_PROJECT_SLUG`

### 🔐 Server Access

* `SSH_HOST`
* `SSH_USERNAME`
* `SSH_PRIVATE_KEY`

---

## 🧠 Best Practices

* Use **separate Infisical projects** for infra and apps
* Use **global env** for shared VPS secrets
* Use branch name mapping for env (`dev`, `prod`)
* Do not store `.env` in Git
* Rotate Infisical credentials regularly
* Enable MFA for Infisical users

---

## 📚 References

* Infisical CLI: [https://infisical.com/docs/cli](https://infisical.com/docs/cli)
* Infisical SDK: [https://infisical.com/docs/sdks](https://infisical.com/docs/sdks)
* GitHub Action: [https://github.com/Infisical/secrets-action](https://github.com/Infisical/secrets-action)
