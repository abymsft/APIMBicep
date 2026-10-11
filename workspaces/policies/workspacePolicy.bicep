@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

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

resource policy 'Microsoft.ApiManagement/service/workspaces/policies@2025-09-01-preview' = {
  parent: workspace
  name: 'policy'
  properties: {
    format: policyFormat
    value: policyValue
  }
}

output id string = policy.id
