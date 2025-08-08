# EC2 Auto-Start Failover POC with Route53 and Lambda

This document details the complete setup process for implementing an auto-start failover mechanism for EC2 instances using Route53 failover records, API Gateway, and Lambda functions.

## Overview

The aim of this POC is to automatically start an EC2 instance (containing an application running as a Docker container) when it's stopped. The system uses Route53 failover records to detect when the primary instance is down and redirects traffic to an API Gateway that triggers a Lambda function to start the EC2 instance.

**Important Note**: Route53 is mandatory for this POC as it provides the failover record functionality. Other DNS management services cannot be used.

## Architecture Flow

1. **Primary**: Route53 → EC2 Instance (with health check)
2. **Failover**: Route53 → API Gateway → Lambda → Start EC2 → Redirect back to primary

## Prerequisites

- AWS Account with appropriate permissions
- Domain name for Route53 hosted zone
- Basic understanding of AWS services (EC2, Route53, Lambda, API Gateway)

## Step-by-Step Implementation

### 1. EC2 Instance Setup

#### 1.1 Create EC2 Instance

- Launch an EC2 instance with an Elastic IP
- Configure Security Group to allow the following ports:
  - **22** (SSH)
  - **80** (HTTP)
  - **443** (HTTPS)
  - **8080** (Application port for Route53 health checks, if you have an https /health endpoint then exposing this port is not needed)

#### 1.2 Install Required Software

Connect to your EC2 instance and install Docker, Docker Compose, Nginx, and Certbot:

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install docker-compose-plugin

# Install Nginx and Certbot
sudo apt install nginx -y
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

#### 1.3 Enable Services for Auto-Start

```bash
sudo systemctl enable docker
sudo systemctl enable nginx
```

### 2. Application Deployment

#### 2.1 Create Docker Compose File

Create a `docker-compose.yml` file for your application:

```yaml
services:
  app:
    image: nginx:latest # your app image
    ports:
      - "8080:80"
    restart: always
```

#### 2.2 Deploy Application

```bash
sudo docker compose up -d
```

### 3. Route53 Configuration

#### 3.1 Create Hosted Zone

Create a Route53 hosted zone for your domain (e.g., `mycompany.com`).

#### 3.2 Create Health Check

1. Navigate to Route53 → Health checks
2. Create a new health check with the following settings:
   - **Type**: HTTP (HTTPS is costlier but can be used if needed, if you have healthcheck endpoint in your app like app.mycompany.com/health then you can create https type healtcheck, otherwise if you only create https healthcheck at this root like app.mycompany.com then it will create a loop and lambda will always start the ec2 and our aim won't be achieved)
   - **URL**: `http://<elastic-ip>:8080`
   - Configure other settings as needed

#### 3.3 Create Primary Failover Record

1. Add an A record with the following settings:
   - **Name**: `testapp.mycompany.com`
   - **Type**: A
   - **Value**: Elastic IP of EC2 instance
   - **Routing Policy**: Failover
   - **Failover Record Type**: Primary
   - **Health Check**: Select the health check created above

### 4. Nginx Reverse Proxy Configuration

#### 4.1 Configure Nginx on Host

Add the following configuration to your Nginx sites-enabled folder (on the host, not in the Docker container):

```nginx
upstream app_servers {
    server localhost:8080;
}

server {
    listen 80;
    server_name app.mycompany.com;

    location / {
        proxy_pass http://app_servers;
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

#### 4.2 Create SSL Certificate

```bash
sudo certbot --nginx --domain app.mycompany.com --agree-tos --no-eff-email --non-interactive --redirect --email hi@example.com
```

### 5. Test Primary Setup

Before proceeding with the failover setup, test your application:

1. Open `https://app.mycompany.com` in your browser
2. Verify the application loads successfully
3. Stop the EC2 instance to proceed with failover setup

### 6. Lambda Function Setup

#### 6.1 Create Lambda Function

1. Navigate to AWS Lambda console
2. Create a new function with the following settings:
   - **Function name**: `auto-start-ec2-func`
   - **Runtime**: Python (latest version)
   - **Trigger type**: HTTP
   - **Authentication**: None  
   - **IAM Role**: Attach role which has ec2 permissions attached, EC2 full access for testing  

#### 6.2 Lambda Function Code

Replace the default code with the following and deploy lambda function:

```python
import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2', region_name='us-east-1')  # Adjust region
    instance_id = 'i-xxxxxxxxx'  # Your EC2 instance ID

    try:
        ec2.start_instances(InstanceIds=[instance_id])
        print(f"Started EC2 instance {instance_id}")
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'text/html'
            },
            'body': """
                <html>
                    <head>
                        <title>Starting Up</title>
                    </head>
                    <body style="font-family: Arial; text-align: center; margin-top: 50px;">
                        <h2>The server is starting...</h2>
                        <p>This may take 1 or 2 minutes. Please refresh the page shortly - https://testapp.promactinfo.net</p>
                        <p>Thank you for your patience.</p>
                    </body>
                </html>
            """
        }
    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'text/plain'
            },
            'body': f"Error starting EC2 instance: {str(e)}"
        }
```

**Important**: Replace `i-xxxxxxxxx` with your actual EC2 instance ID and adjust the region as needed.

### 7. API Gateway Setup

#### 7.1 Create API Gateway

1. Navigate to API Gateway console
2. Create a new HTTP API with the following settings:
   - **Name**: `auto-start-ec2-lambda-failover-api`
   - **Authentication**: None
   - **Type**: HTTP

#### 7.2 Configure Integration

1. Add integration and select your Lambda function
2. Configure the route:
   - **Method**: ANY
   - **Resource path**: `/`
3. Deploy to default stage (should auto-deploy)

#### 7.3 Create Custom Domain Name

**This is a critical step** - without this, the API Gateway endpoint won't be visible in Route53 dropdown.

1. Navigate to API Gateway → Custom domain names
2. Create custom domain with the following settings:
   - **Domain name**: `app.mycompany.com` (same as your application domain, otherwise it won't work and failover will throw an error 404, due to host header mismatch)
   - Keep other settings as default
3. Configure API mappings:
   - Select your Lambda function from dropdown
   - Keep other settings as default
4. **Important**: Attach the ACM certificate to the custom domain, ACM cert should be in us-east-1 and I would recommend wildcard certificate

### 8. Create Secondary Failover Record

#### 8.1 Add Secondary A Record

1. In Route53, create another A record with the following settings:
   - **Name**: `app.mycompany.com`
   - **Type**: A
   - **Routing Policy**: Failover
   - **Failover Record Type**: Secondary
   - **Alias**: Yes
   - **Route traffic to**: API Gateway API
   - **Region**: Select your region
   - **API Gateway**: Select your API Gateway URL
   - **Health Check**: Do NOT add a health check for secondary record

## Testing the Complete Setup

### Test Failover Mechanism

1. Ensure your EC2 instance is stopped
2. Navigate to `https://app.mycompany.com` in your browser
3. The request should:
   - Hit the primary record (which will be unhealthy)
   - Failover to the secondary record
   - Route to API Gateway → Lambda
   - Display the "server is starting" message
   - Lambda starts the EC2 instance
   - Once health check becomes healthy, traffic automatically routes back to primary

## Additional Tips and Considerations

### Cost Optimization

- Create an additional Lambda function that monitors EC2 requests hourly and stops the instance when not in use to save costs

### Important Technical Notes

1. **Failover Record Limitations**: You cannot use Lambda URLs directly with failover records - API Gateway is required
2. **Record Type Consistency**: Both failover records must be A type. The following combination will cause Route53 errors:
   - ❌ 1 A type pointing to EC2 IP + 1 CNAME pointing to API Gateway
   - ✅ 2 A type records (primary to EC2, secondary to API Gateway alias)

### Security Considerations

- Ensure proper IAM roles and permissions are configured
- Use HTTPS for production environments
- Implement proper monitoring and logging

### Monitoring and Maintenance

- Set up CloudWatch alerts for Lambda function errors
- Monitor health check status
- Regular testing of failover mechanism
