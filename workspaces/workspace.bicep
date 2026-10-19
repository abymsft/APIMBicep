@description('Name of the existing API Management service')
param apimServiceName string

@description('Workspace resource name')
@minLength(1)
@maxLength(80)
param workspaceName string

@description('Workspace display name')
param displayName string

@description('Workspace description')
param workspaceDescription string = ''

@description('Gateway the workspace is served on. Left empty, it defaults to workspaceAndDefault on BasicV2 and to the service default otherwise.')
@allowed([
  ''
  'workspaceAndDefault'
])
param serveOn string = ''

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

var effectiveServeOn = !empty(serveOn) ? serveOn : (apim.sku.name == 'BasicV2' ? 'workspaceAndDefault' : '')

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' = {
  parent: apim
  name: workspaceName
  properties: {
    displayName: displayName
    description: workspaceDescription
    // serveOn is accepted by the REST API but missing from the published Bicep type
    #disable-next-line BCP037
    serveOn: empty(effectiveServeOn) ? null : effectiveServeOn
  }
}

output id string = workspace.id
output name string = workspace.name
