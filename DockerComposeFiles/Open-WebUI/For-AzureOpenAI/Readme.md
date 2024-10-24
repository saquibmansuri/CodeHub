# Connect Open-WebUI with Azure OpenAI using LLM Proxy 

## References
- Github Repository - https://github.com/open-webui/open-webui
- Official Documentation - https://docs.openwebui.com/
- Connect Open-WebUI with Azure OpenAI using LLM Proxy - https://uright.ca/blogs/2024-07-29-unlocking-the-power-of-azure-openai-on-open-webui/

## Step1: Edit compose file & fill the azure open ai related environment variables

## Step2: Edit config file if you want to change the model
``` file location - config/litellm_config.yaml ```

## Step3: Start the services
```docker compose up -d```

## Step4: Check if the LLM proxy service is working
Note: model name should match with the name given in the config file (model: "azure-gpt-4o")
```
curl --location 'http://0.0.0.0:4000/chat/completions' \
     --header 'Content-Type: application/json' \
     --data '{
     "model": "azure-gpt-4o",
     "messages": [
         {
         "role": "user",
         "content": "What is the purpose of life?"
         }
     ]
 }'
```

## Step5: Configure connection in open webui
- On Open WebUI, click on the top-right profile icon and go to the Admin Panel.
- Under the Admin Panel, select Settings, and click on Connections from the left navigation menu.
- Update the OpenAI API Endpoint as follows:
  - Endpoint: http://host.docker.internal:4000     # this is our proxy server
  - Secret: AnyDummyValue                          # value of this doesn't matter since we already provided all secrets in the proxy container -->
  - Save Connection

## All Set!!!
