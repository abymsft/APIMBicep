@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Backend resource name')
@minLength(1)
@maxLength(80)
param backendName string

@description('Runtime URL of the backend')
param url string

@allowed([
  'http'
  'soap'
])
param protocol string = 'http'

@description('Backend title')
param title string = ''

@description('Backend description')
param backendDescription string = ''

@description('Backend credentials contract (header, query, authorization, certificate)')
param credentials object = {}

@description('Backend TLS properties')
param tls object = {
  validateCertificateChain: true
  validateCertificateName: true
}

@description('Backend circuit breaker contract ({ rules: [...] }); empty to disable')
param circuitBreaker object = {}

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource backend 'Microsoft.ApiManagement/service/workspaces/backends@2025-09-01-preview' = {
  parent: workspace
  name: backendName
  properties: {
    url: url
    protocol: protocol
    title: empty(title) ? null : title
    description: empty(backendDescription) ? null : backendDescription
    credentials: empty(credentials) ? null : credentials
    tls: tls
    circuitBreaker: empty(circuitBreaker) ? null : circuitBreaker
  }
}

output id string = backend.id
