@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Name of the existing product')
param productName string

@description('Name of the existing group to link to the product')
param groupName string

@description('Link resource name')
param linkName string = groupName

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

resource group 'Microsoft.ApiManagement/service/workspaces/groups@2025-09-01-preview' existing = {
  parent: workspace
  name: groupName
}

resource groupLink 'Microsoft.ApiManagement/service/workspaces/products/groupLinks@2025-09-01-preview' = {
  parent: product
  name: linkName
  properties: {
    groupId: group.id
  }
}

output id string = groupLink.id
