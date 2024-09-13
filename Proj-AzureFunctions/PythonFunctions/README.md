# Create python azure function in vscode
https://learn.microsoft.com/en-us/azure/azure-functions/functions-develop-vs-code?tabs=node-v4%2Cpython-v2%2Cisolated-process%2Cquick-create&pivots=programming-language-python

# AzureFunction
This repo contains sample azure python functions (anonymous http trigger) and ci/cd pipelines to deploy.
Azure keeps on adding new model versions quite frequently, so I will try to keep this repo updated with the new model versions


# IN MODEL-V1
If you want to make the function to be accessed by autherization then change this line in function.json
"authLevel": "anonymous",  ------>>>  "authLevel": "Function",

# Once the function is deployed then test it using hitting function URL with parameter ( I would suggest from postman)
Example: https://myfunction.azurewebsites.net/api/Function1?name=saquib