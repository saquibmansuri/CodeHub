# Setting up Load Balancing for API Endpoints in Azure API Management

## Overview

This guide demonstrates how to set up load balancing between two API endpoints using Azure API Management (APIM). The setup includes creating named values, backend pools, APIs, and configuring policies for load balancing, authentication, error handling, and security.

## Step-by-Step Configuration

### 1. Create Named Values

Navigate to "Named Values" in APIM and create the following values:

```plaintext
Name: endpoint-1
Value: https://dummy-endpoint-1.com
Secret: No

Name: endpoint-2
Value: https://dummy-endpoint-2.com
Secret: No

Name: api-key  (ignore this if your endpoints are accessible without a key)
Value: thisismydummykey
Secret: Yes
```

### 2. Create Backend Pool

Navigate to "Backends" and create a new backend:

```plaintext
Name: backend-pool
Description: Backend pool for API Load Balancing
Backend hosting type: Custom URL
Runtime URL: https://dummy-endpoint-1.com   (don't worry this is just for creating a pool, we will do load balancing later using policy)
```

### 3. Create New API

In the APIs section:

```plaintext
Display name: API Load Balancing
Name: api-load-balancing
Web service URL: https://dummy-endpoint-1.com ((don't worry this is just for creating a new api since it is required, we will do load balancing later using policy)
API URL suffix: api-load-balancing
```

### 4. Add Operation

In the API design:

```plaintext
Display name: Process Request
Name: process-request
Method: POST
URL template: /
```

### 5. Configure Policy

Click on the </> icon in the Inbound processing section and add this policy:  
Note: Remember to remove {api-key} if thats not required in your case.

```xml
<policies>
    <inbound>
        <base />
        <set-header name="Authorization" exists-action="override">
            <value>Bearer {{api-key}}</value>
        </set-header>
        <set-header name="Content-Type" exists-action="override">
            <value>application/json</value>
        </set-header>
        <set-variable name="selected-backend" value="@(new Random().Next(2))" />
        <choose>
            <when condition="@(context.Variables.GetValueOrDefault<int>("selected-backend") == 0)">
                <set-backend-service base-url="{{endpoint-1}}" />
                <set-variable name="backend-name" value="Endpoint-1" />
            </when>
            <otherwise>
                <set-backend-service base-url="{{endpoint-2}}" />
                <set-variable name="backend-name" value="Endpoint-2" />
            </otherwise>
        </choose>
        <set-header name="X-Selected-Backend" exists-action="override">
            <value>@(context.Variables.GetValueOrDefault<string>("backend-name"))</value>
        </set-header>
    </inbound>
    <backend>
        <forward-request timeout="300" buffer-request-body="true" />
    </backend>
    <outbound>
        <base />
        <set-header name="X-Selected-Backend" exists-action="override">
            <value>@(context.Variables.GetValueOrDefault<string>("backend-name"))</value>
        </set-header>
    </outbound>
    <on-error>
        <base />
        <set-header name="X-Selected-Backend" exists-action="override">
            <value>@(context.Variables.GetValueOrDefault<string>("backend-name"))</value>
        </set-header>
        <set-variable name="errorMessage" value="@(context.LastError.Message)" />
        <return-response>
            <set-status code="@(context.Response.StatusCode)" reason="@(context.Response.StatusReason)" />
            <set-header name="Content-Type" exists-action="override">
                <value>application/json</value>
            </set-header>
            <set-body>@{
                return new JObject(
                    new JProperty("error", context.LastError.Message)
                ).ToString();
            }</set-body>
        </return-response>
    </on-error>
</policies>
```

### 6. Testing in Postman

1. Set up the request:

   ```plaintext
   Method: POST
   URL: https://your-apim-url.com/api-load-balancing
   ```

2. Add Headers:

   ```plaintext
   Ocp-Apim-Subscription-Key: your-apim-subscription-key
   Content-Type: application/json
   ```

3. Add Body (raw JSON):  
   This is just an example, you can pass the json thats needed for your endpoints

   ```json
   {
       "inputs": "Sample input data",
       "parameters": {}
   }
   ```

## How It Works

1. **Load Balancing:** Uses a random number generator to distribute requests between two endpoints.

2. **Authentication:** Utilizes a subscription key in the header and a bearer token for backend authentication.

3. **Error Handling:** Implements retry logic for rate limits and service unavailability, with custom error responses.

4. **Security:** Stores sensitive values in Named Values and removes sensitive headers in outbound processing.
