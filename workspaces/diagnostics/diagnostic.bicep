@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Diagnostic name, e.g. applicationinsights or azuremonitor')
param diagnosticName string = 'applicationinsights'

@description('Resource ID of the target logger')
param loggerId string

@minValue(0)
@maxValue(100)
param samplingPercentage int = 100

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

resource diagnostic 'Microsoft.ApiManagement/service/workspaces/diagnostics@2025-09-01-preview' = {
  parent: workspace
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
