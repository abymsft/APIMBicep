@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Name of the existing tag')
param tagName string

@description('Name of the API that owns the operation')
param apiName string

@description('Name of the existing operation to tag')
param operationName string

@description('Link resource name')
param linkName string = operationName

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource tag 'Microsoft.ApiManagement/service/workspaces/tags@2025-09-01-preview' existing = {
  parent: workspace
  name: tagName
}

resource api 'Microsoft.ApiManagement/service/workspaces/apis@2025-09-01-preview' existing = {
  parent: workspace
  name: apiName
}

resource operation 'Microsoft.ApiManagement/service/workspaces/apis/operations@2025-09-01-preview' existing = {
  parent: api
  name: operationName
}

resource operationLink 'Microsoft.ApiManagement/service/workspaces/tags/operationLinks@2025-09-01-preview' = {
  parent: tag
  name: linkName
  properties: {
    operationId: operation.id
  }
}

output id string = operationLink.id
