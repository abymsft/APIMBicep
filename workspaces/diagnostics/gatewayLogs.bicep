@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Diagnostic setting name')
param diagnosticSettingName string = 'gateway-logs'

@description('Resource ID of the Log Analytics workspace that receives the logs')
param logAnalyticsWorkspaceId string

@description('Log Analytics destination table mode: AzureDiagnostics (null) or resource-specific')
@allowed([
  ''
  'Dedicated'
])
param logAnalyticsDestinationType string = ''

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticSettingName
  scope: workspace
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logAnalyticsDestinationType: empty(logAnalyticsDestinationType) ? null : logAnalyticsDestinationType
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
    ]
  }
}

output id string = diagnosticSetting.id
