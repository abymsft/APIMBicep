@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Tag resource name')
@minLength(1)
@maxLength(80)
param tagName string

@description('Tag display name')
@minLength(1)
@maxLength(160)
param displayName string

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource tag 'Microsoft.ApiManagement/service/workspaces/tags@2025-09-01-preview' = {
  parent: workspace
  name: tagName
  properties: {
    displayName: displayName
  }
}

output id string = tag.id
output name string = tag.name
