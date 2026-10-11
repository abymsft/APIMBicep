@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Group resource name')
@minLength(1)
@maxLength(80)
param groupName string

@description('Group display name')
@minLength(1)
@maxLength(300)
param displayName string

@description('Group description')
param groupDescription string = ''

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource group 'Microsoft.ApiManagement/service/workspaces/groups@2025-09-01-preview' = {
  parent: workspace
  name: groupName
  properties: {
    displayName: displayName
    description: groupDescription
    type: 'custom'
  }
}

output id string = group.id
output name string = group.name
