# Keyless SSH into EC2 using AWS Systems Manager (SSM)
## + GitHub Actions (OIDC) for Keyless Deployments

---

## Overview

This document explains how to:

1. SSH into EC2 **without SSH keys** using **AWS Systems Manager (SSM)**
2. Make an EC2 instance appear as a **managed node in SSM Inventory**
3. Use **GitHub Actions + OIDC** to run commands on EC2 via SSM (no SSH, no IAM user keys)
4. Run deployments securely using **SSM SendCommand**

This setup is **enterprise-grade**, fully auditable, and eliminates:
- SSH keys
- Port 22
- Bastion hosts
- Long-lived IAM credentials

---

## Part 1: Keyless SSH into EC2 using SSM (Session Manager)

### Architecture

```
Your Browser / AWS CLI
↓
AWS Systems Manager
↓
SSM Agent
↓
EC2 Instance
```

No inbound ports are required.

---

## Prerequisites (EC2 Side)

### 1. EC2 Instance Requirements

- **Operating System**
  - Any supported OS
- Outbound internet access  
  *(or VPC Interface Endpoints for SSM in private subnets)*  

> ⚠️ Ubuntu AMIs already have the SSM Agent installed by default.

### 2. IAM Role for EC2 (Mandatory)

Attach this IAM policy to the EC2 Instance Profile so that the instance can come under SSM inventory:

```
AmazonSSMManagedInstanceCore
```

This policy allows the instance to:
- Register with AWS Systems Manager
- Automatically appear in SSM Inventory
- Accept Session Manager and Run Command requests

✅ **As soon as this role is attached, the instance is automatically registered in SSM.**

⚠️ **Without this policy, the instance will NOT show up in SSM.**

### 3. Confirm EC2 is Managed by SSM

AWS Console → Systems Manager → Fleet Manager → Managed nodes

You should see:
- Status: Online
- Platform: Linux
- Agent: Running

---

## SSH into EC2 (No Key, No Port 22)

### Option A: Browser-based SSH

EC2 → Instance → Connect → Session Manager → Connect

### Option B: CLI-based SSH (Recommended)

**Install Session Manager Plugin**

https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

**Connect:**
```bash
aws ssm start-session --target i-xxxxxxxx
```

This behaves like SSH but:
- Uses IAM for authentication
- Is fully logged in CloudTrail
- Requires no SSH keys

---

## Part 2: Keyless EC2 Access from GitHub Actions using OIDC

This allows GitHub to run commands on EC2 using SSM without SSH or IAM user keys.

### Prerequisites (AWS Side)

#### 1. Create IAM Role for GitHub Actions

- Trusted entity: Web Identity
- OIDC Provider: token.actions.githubusercontent.com
- Audience: sts.amazonaws.com

**Trust Policy (Example)**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:ORG/REPO:*"
        }
      }
    }
  ]
}
```

#### 2. Permissions Policy for GitHub Role

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:SendCommand",
        "ssm:ListCommandInvocations",
        "ssm:DescribeInstanceInformation",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## Part 3: GitHub Actions Workflow (Keyless SSM Execution)

### What This Does

- Checks out code
- Authenticates to AWS using OIDC
- Runs commands on EC2 via SSM SendCommand
- No SSH keys
- No IAM user credentials

### .github/workflows/deploy-via-ssm.yml

```yaml
name: Deploy to EC2 via SSM (Keyless)

on:
  push:
    branches: [ "main" ]

jobs:
  deploy:
    runs-on: ubuntu-latest

    permissions:
      id-token: write
      contents: read

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/GitHubSSMDeployRole
          aws-region: ap-south-1

      - name: Run commands on EC2 using SSM
        uses: <ACTION_OWNER>/ssm-send-command-action@v1
        with:
          instanceId: i-0abcdef123456
          workingDirectory: /home/ubuntu/application
          commands: |
            whoami
            git pull
            docker compose down
            docker compose up -d --build
```

**Replace:**
- `<ACCOUNT_ID>`
- `<ACTION_OWNER>`
- `instanceId`

---

## Security Advantages

- No port 22
- No SSH keys
- No secrets in GitHub
- IAM-based, short-lived credentials

---

## Summary

| Feature | SSH | SSM |
|---------|-----|-----|
| SSH keys | Required | ❌ |
| Port 22 | Required | ❌ |
| IAM audit | ❌ | ✅ |
| GitHub secrets | Private key | ❌ |
| Enterprise ready | ❌ | ✅ |
