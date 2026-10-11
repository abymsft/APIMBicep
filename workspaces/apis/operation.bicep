@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Name of the existing API')
param apiName string

@description('Operation resource name')
@minLength(1)
@maxLength(80)
param operationName string

@description('Operation display name')
@minLength(1)
@maxLength(300)
param displayName string

@description('HTTP method, e.g. GET, POST')
param method string

@description('Relative URL template, e.g. /items/{id}')
@minLength(1)
@maxLength(1000)
param urlTemplate string

@description('Operation description')
param operationDescription string = ''

@description('URL template parameters')
param templateParameters array = []

@description('Request definition (queryParameters, headers, representations)')
param request object = {}

@description('Response definitions')
param responses array = []

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource api 'Microsoft.ApiManagement/service/workspaces/apis@2025-09-01-preview' existing = {
  parent: workspace
  name: apiName
}

resource operation 'Microsoft.ApiManagement/service/workspaces/apis/operations@2025-09-01-preview' = {
  parent: api
  name: operationName
  properties: {
    displayName: displayName
    method: method
    urlTemplate: urlTemplate
    description: operationDescription
    templateParameters: templateParameters
    request: request
    responses: responses
  }
}

output id string = operation.id
output name string = operation.name
