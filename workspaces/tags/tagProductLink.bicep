@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Name of the existing tag')
param tagName string

@description('Name of the existing product to tag')
param productName string

@description('Link resource name')
param linkName string = productName

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource tag 'Microsoft.ApiManagement/service/workspaces/tags@2025-09-01-preview' existing = {
  parent: workspace
  name: tagName
}

resource product 'Microsoft.ApiManagement/service/workspaces/products@2025-09-01-preview' existing = {
  parent: workspace
  name: productName
}

resource productLink 'Microsoft.ApiManagement/service/workspaces/tags/productLinks@2025-09-01-preview' = {
  parent: tag
  name: linkName
  properties: {
    productId: product.id
  }
}

output id string = productLink.id
