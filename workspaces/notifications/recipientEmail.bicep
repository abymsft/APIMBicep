@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Name of the existing notification')
param notificationName string

@description('Email address of the recipient')
param email string

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource notification 'Microsoft.ApiManagement/service/workspaces/notifications@2025-09-01-preview' existing = {
  parent: workspace
  name: notificationName
}

resource recipientEmail 'Microsoft.ApiManagement/service/workspaces/notifications/recipientEmails@2025-09-01-preview' = {
  parent: notification
  name: email
}

output id string = recipientEmail.id
