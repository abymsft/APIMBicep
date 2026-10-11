@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Subscription resource name (sid)')
@minLength(1)
@maxLength(80)
param subscriptionName string

@description('Subscription display name')
@minLength(1)
@maxLength(100)
param displayName string

@description('Scope: a full resource ID of a workspace product (/products/{id}), API (/apis/{id}) or all APIs (/apis)')
param scope string

param allowTracing bool = false

@allowed([
  'active'
  'cancelled'
  'expired'
  'rejected'
  'submitted'
  'suspended'
])
param state string = 'active'

@secure()
param primaryKey string = ''

@secure()
param secondaryKey string = ''

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource subscription 'Microsoft.ApiManagement/service/workspaces/subscriptions@2025-09-01-preview' = {
  parent: workspace
  name: subscriptionName
  properties: {
    displayName: displayName
    scope: scope
    allowTracing: allowTracing
    state: state
    primaryKey: empty(primaryKey) ? null : primaryKey
    secondaryKey: empty(secondaryKey) ? null : secondaryKey
  }
}

output id string = subscription.id
