@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Policy fragment resource name')
param fragmentName string

@description('Fragment content')
param fragmentValue string

@allowed([
  'rawxml'
  'xml'
])
param fragmentFormat string = 'rawxml'

param fragmentDescription string = ''

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource fragment 'Microsoft.ApiManagement/service/workspaces/policyFragments@2025-09-01-preview' = {
  parent: workspace
  name: fragmentName
  properties: {
    format: fragmentFormat
    value: fragmentValue
    description: fragmentDescription
  }
}

output id string = fragment.id
