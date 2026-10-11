@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Name of the existing API')
param apiName string

@description('Diagnostic name, e.g. applicationinsights or azuremonitor')
param diagnosticName string = 'applicationinsights'

@description('Resource ID of the target logger')
param loggerId string

@description('Sampling percentage (0-100)')
@minValue(0)
@maxValue(100)
param samplingPercentage int = 100

@description('Log client IP address')
param logClientIp bool = true

@allowed([
  'Legacy'
  'None'
  'W3C'
])
param httpCorrelationProtocol string = 'W3C'

@allowed([
  'error'
  'information'
  'verbose'
])
param verbosity string = 'information'

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource api 'Microsoft.ApiManagement/service/workspaces/apis@2025-09-01-preview' existing = {
  parent: workspace
  name: apiName
}

resource diagnostic 'Microsoft.ApiManagement/service/workspaces/apis/diagnostics@2025-09-01-preview' = {
  parent: api
  name: diagnosticName
  properties: {
    loggerId: loggerId
    alwaysLog: 'allErrors'
    logClientIp: logClientIp
    httpCorrelationProtocol: httpCorrelationProtocol
    verbosity: verbosity
    sampling: {
      samplingType: 'fixed'
      percentage: samplingPercentage
    }
  }
}

output id string = diagnostic.id
