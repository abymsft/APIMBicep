@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Name of the existing product')
param productName string

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

resource product 'Microsoft.ApiManagement/service/workspaces/products@2025-09-01-preview' existing = {
  parent: workspace
  name: productName
}

resource policy 'Microsoft.ApiManagement/service/workspaces/products/policies@2025-09-01-preview' = {
  parent: product
  name: 'policy'
  properties: {
    format: policyFormat
    value: policyValue
  }
}

output id string = policy.id
