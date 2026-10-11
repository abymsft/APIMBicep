@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Product resource name')
@minLength(1)
@maxLength(80)
param productName string

@description('Product display name')
@minLength(1)
@maxLength(300)
param displayName string

param productDescription string = ''

@allowed([
  'notPublished'
  'published'
])
param state string = 'published'

param subscriptionRequired bool = true

param approvalRequired bool = false

@description('Max subscriptions per user; 0 or negative leaves unlimited')
param subscriptionsLimit int = 1

param terms string = ''

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource product 'Microsoft.ApiManagement/service/workspaces/products@2025-09-01-preview' = {
  parent: workspace
  name: productName
  properties: {
    displayName: displayName
    description: productDescription
    state: state
    subscriptionRequired: subscriptionRequired
    approvalRequired: subscriptionRequired ? approvalRequired : null
    subscriptionsLimit: subscriptionRequired && subscriptionsLimit > 0 ? subscriptionsLimit : null
    terms: empty(terms) ? null : terms
  }
}

output id string = product.id
output name string = product.name
