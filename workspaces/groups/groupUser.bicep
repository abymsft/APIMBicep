@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Name of the existing group')
param groupName string

@description('User resource name (user id) to add to the group')
param userName string

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource group 'Microsoft.ApiManagement/service/workspaces/groups@2025-09-01-preview' existing = {
  parent: workspace
  name: groupName
}

resource groupUser 'Microsoft.ApiManagement/service/workspaces/groups/users@2025-09-01-preview' = {
  parent: group
  name: userName
}

output id string = groupUser.id
