@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('API version set resource name')
@minLength(1)
@maxLength(80)
param versionSetName string

@description('Display name')
@minLength(1)
@maxLength(100)
param displayName string

@description('Description')
param versionSetDescription string = ''

@allowed([
  'Header'
  'Query'
  'Segment'
])
param versioningScheme string = 'Segment'

@description('Header name when versioningScheme is Header')
param versionHeaderName string = ''

@description('Query parameter name when versioningScheme is Query')
param versionQueryName string = ''

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource versionSet 'Microsoft.ApiManagement/service/workspaces/apiVersionSets@2025-09-01-preview' = {
  parent: workspace
  name: versionSetName
  properties: {
    displayName: displayName
    description: versionSetDescription
    versioningScheme: versioningScheme
    versionHeaderName: versioningScheme == 'Header' ? versionHeaderName : null
    versionQueryName: versioningScheme == 'Query' ? versionQueryName : null
  }
}

output id string = versionSet.id
