@description('Name of the existing API Management service')
param apimServiceName string

@description('Workspace resource name')
@minLength(1)
@maxLength(80)
param workspaceName string

@description('Workspace display name')
param displayName string

@description('Workspace description')
param workspaceDescription string = ''

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' = {
  parent: apim
  name: workspaceName
  properties: {
    displayName: displayName
    description: workspaceDescription
  }
}

output id string = workspace.id
output name string = workspace.name
