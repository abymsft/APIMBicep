@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Name of the existing API')
param apiName string

@description('Release resource name')
@minLength(1)
@maxLength(80)
param releaseName string

@description('Release notes')
param notes string = ''

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

resource release 'Microsoft.ApiManagement/service/workspaces/apis/releases@2025-09-01-preview' = {
  parent: api
  name: releaseName
  properties: {
    apiId: api.id
    notes: notes
  }
}

output id string = release.id
