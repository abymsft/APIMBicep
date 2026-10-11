@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Name of the existing API')
param apiName string

@description('Name of the existing operation')
param operationName string

@description('Policy content')
param policyValue string

@description('Policy format')
param policyFormat string = 'rawxml'

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

resource operation 'Microsoft.ApiManagement/service/workspaces/apis/operations@2025-09-01-preview' existing = {
  parent: api
  name: operationName
}

resource policy 'Microsoft.ApiManagement/service/workspaces/apis/operations/policies@2025-09-01-preview' = {
  parent: operation
  name: 'policy'
  properties: {
    format: policyFormat
    value: policyValue
  }
}

output id string = policy.id
