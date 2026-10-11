@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Notification name, e.g. RequestPublisherNotificationMessage, AccountClosedPublisher, QuotaLimitApproachingPublisherNotificationMessage')
param notificationName string

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource notification 'Microsoft.ApiManagement/service/workspaces/notifications@2025-09-01-preview' = {
  parent: workspace
  name: notificationName
}

output id string = notification.id
