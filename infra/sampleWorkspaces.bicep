// Deploys the three sample workspaces (petstore, jsonplaceholder, httpbin) into an existing APIM service.

targetScope = 'resourceGroup'

@description('Name of the existing API Management service (BasicV2)')
param apimServiceName string

@description('Optional Log Analytics workspace resource ID; enables a GatewayLogs diagnostic setting per workspace')
param logAnalyticsWorkspaceId string = ''

module petstore 'sampleWorkspace.bicep' = {
  name: 'sample-petstore'
  params: {
    apimServiceName: apimServiceName
    workspaceName: 'petstore'
    displayName: 'Petstore'
    workspaceDescription: 'Swagger Petstore sample'
    backendArtifact: loadJsonContent('../samples/petstore/backends/backend.json')
    namedValues: loadJsonContent('../samples/petstore/namedValues/namedValues.json')
    groupArtifact: loadJsonContent('../samples/petstore/groups/group.json')
    productArtifact: loadJsonContent('../samples/petstore/products/product.json')
    subscriptionArtifact: loadJsonContent('../samples/petstore/subscriptions/subscription.json')
    apiName: 'petstore'
    apiDisplayName: 'Swagger Petstore'
    apiPath: 'petstore'
    openApiContent: loadTextContent('../samples/petstore/apis/petstore/openapi.json')
    apiPolicyXml: loadTextContent('../samples/petstore/apis/petstore/policy.xml')
    productPolicyXml: loadTextContent('../samples/petstore/products/policy.xml')
    workspacePolicyXml: loadTextContent('../samples/petstore/policies/workspace.xml')
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

module jsonplaceholder 'sampleWorkspace.bicep' = {
  name: 'sample-jsonplaceholder'
  params: {
    apimServiceName: apimServiceName
    workspaceName: 'jsonplaceholder'
    displayName: 'JSONPlaceholder'
    workspaceDescription: 'JSONPlaceholder sample'
    backendArtifact: loadJsonContent('../samples/jsonplaceholder/backends/backend.json')
    namedValues: loadJsonContent('../samples/jsonplaceholder/namedValues/namedValues.json')
    groupArtifact: loadJsonContent('../samples/jsonplaceholder/groups/group.json')
    productArtifact: loadJsonContent('../samples/jsonplaceholder/products/product.json')
    subscriptionArtifact: loadJsonContent('../samples/jsonplaceholder/subscriptions/subscription.json')
    apiName: 'jsonplaceholder'
    apiDisplayName: 'JSONPlaceholder'
    apiPath: 'jsonplaceholder'
    openApiContent: loadTextContent('../samples/jsonplaceholder/apis/jsonplaceholder/openapi.json')
    apiPolicyXml: loadTextContent('../samples/jsonplaceholder/apis/jsonplaceholder/policy.xml')
    productPolicyXml: loadTextContent('../samples/jsonplaceholder/products/policy.xml')
    workspacePolicyXml: loadTextContent('../samples/jsonplaceholder/policies/workspace.xml')
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

module httpbin 'sampleWorkspace.bicep' = {
  name: 'sample-httpbin'
  params: {
    apimServiceName: apimServiceName
    workspaceName: 'httpbin'
    displayName: 'httpbin'
    workspaceDescription: 'httpbin sample'
    backendArtifact: loadJsonContent('../samples/httpbin/backends/backend.json')
    namedValues: loadJsonContent('../samples/httpbin/namedValues/namedValues.json')
    groupArtifact: loadJsonContent('../samples/httpbin/groups/group.json')
    productArtifact: loadJsonContent('../samples/httpbin/products/product.json')
    subscriptionArtifact: loadJsonContent('../samples/httpbin/subscriptions/subscription.json')
    apiName: 'httpbin'
    apiDisplayName: 'httpbin'
    apiPath: 'httpbin'
    openApiContent: loadTextContent('../samples/httpbin/apis/httpbin/openapi.json')
    apiPolicyXml: loadTextContent('../samples/httpbin/apis/httpbin/policy.xml')
    productPolicyXml: loadTextContent('../samples/httpbin/products/policy.xml')
    workspacePolicyXml: loadTextContent('../samples/httpbin/policies/workspace.xml')
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}
