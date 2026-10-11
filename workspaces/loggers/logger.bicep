@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Logger resource name')
@minLength(1)
@maxLength(80)
param loggerName string

@allowed([
  'applicationInsights'
  'azureEventHub'
  'azureMonitor'
])
param loggerType string = 'applicationInsights'

@description('Resource ID of the log target (Application Insights or Event Hub namespace)')
param resourceId string = ''

@description('Logger credentials, e.g. { instrumentationKey: \'{{named-value}}\' }')
@secure()
param credentials object = {}

param isBuffered bool = true

param loggerDescription string = ''

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource logger 'Microsoft.ApiManagement/service/workspaces/loggers@2025-09-01-preview' = {
  parent: workspace
  name: loggerName
  properties: {
    loggerType: loggerType
    resourceId: empty(resourceId) ? null : resourceId
    credentials: empty(credentials) ? null : credentials
    isBuffered: isBuffered
    description: empty(loggerDescription) ? null : loggerDescription
  }
}

output id string = logger.id
