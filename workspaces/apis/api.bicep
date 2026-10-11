@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('API resource name')
@minLength(1)
@maxLength(256)
param apiName string

@description('API display name')
@minLength(1)
@maxLength(300)
param displayName string

@description('Relative URL uniquely identifying this API within the workspace')
@maxLength(400)
param path string

@description('Absolute URL of the backend service implementing this API')
param serviceUrl string = ''

@description('API description')
param apiDescription string = ''

@description('Protocols the API is available on')
param protocols array = [
  'https'
]

@description('Whether a subscription is required to access the API')
param subscriptionRequired bool = true

@description('Import format, e.g. openapi, openapi+json, openapi-link, swagger-link-json')
param format string = ''

@description('Content to import when format is set (inline spec or link)')
param value string = ''

@description('Resource ID of an API version set')
param apiVersionSetId string = ''

@description('API version identifier (requires apiVersionSetId)')
param apiVersion string = ''

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource api 'Microsoft.ApiManagement/service/workspaces/apis@2025-09-01-preview' = {
  parent: workspace
  name: apiName
  properties: {
    displayName: displayName
    path: path
    description: apiDescription
    serviceUrl: empty(serviceUrl) ? null : serviceUrl
    protocols: protocols
    subscriptionRequired: subscriptionRequired
    format: empty(format) ? null : format
    value: empty(value) ? null : value
    apiVersionSetId: empty(apiVersionSetId) ? null : apiVersionSetId
    apiVersion: empty(apiVersion) ? null : apiVersion
  }
}

output id string = api.id
output name string = api.name
