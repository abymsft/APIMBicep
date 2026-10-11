@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Name of the existing product')
param productName string

@description('Name of the existing API to link to the product')
param apiName string

@description('Link resource name')
param linkName string = apiName

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

resource api 'Microsoft.ApiManagement/service/workspaces/apis@2025-09-01-preview' existing = {
  parent: workspace
  name: apiName
}

resource apiLink 'Microsoft.ApiManagement/service/workspaces/products/apiLinks@2025-09-01-preview' = {
  parent: product
  name: linkName
  properties: {
    apiId: api.id
  }
}

output id string = apiLink.id
