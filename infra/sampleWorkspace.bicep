// Deploys one sample workspace (workspace, backend, named values, API, group, product, subscription)
// into an existing API Management service using the granular modules in ../workspaces.

targetScope = 'resourceGroup'

param apimServiceName string
param workspaceName string
param displayName string
param workspaceDescription string = ''

@description('Backend artifact: { name, properties: { title, description, protocol, url } }')
param backendArtifact object

@description('Named value artifacts: [{ name, properties: { displayName, value, tags } }]')
param namedValues array

@description('Group artifact: { name, properties: { displayName, description } }')
param groupArtifact object

@description('Product artifact: { name, properties: { displayName, description, ... } }')
param productArtifact object

@description('Subscription artifact: { name, properties: { displayName } }')
param subscriptionArtifact object

param apiName string
param apiDisplayName string
param apiPath string
param openApiContent string
param apiPolicyXml string
param productPolicyXml string
param workspacePolicyXml string

@description('Optional Log Analytics workspace resource ID for the GatewayLogs diagnostic setting')
param logAnalyticsWorkspaceId string = ''

module workspace '../workspaces/workspace.bicep' = {
  name: 'ws-${workspaceName}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: workspaceName
    displayName: displayName
    workspaceDescription: workspaceDescription
  }
}

module workspacePolicy '../workspaces/policies/workspacePolicy.bicep' = {
  name: 'wspol-${workspaceName}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: workspace.outputs.name
    policyValue: workspacePolicyXml
  }
}

module namedValueModules '../workspaces/namedValues/namedValue.bicep' = [for nv in namedValues: {
  name: 'nv-${workspaceName}-${nv.name}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: workspace.outputs.name
    namedValueName: nv.name
    displayName: nv.properties.displayName
    value: nv.properties.value
    tags: nv.properties.?tags ?? []
  }
}]

module backend '../workspaces/backends/backend.bicep' = {
  name: 'be-${workspaceName}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: workspace.outputs.name
    backendName: backendArtifact.name
    url: backendArtifact.properties.url
    title: backendArtifact.properties.?title ?? ''
    backendDescription: backendArtifact.properties.?description ?? ''
    circuitBreaker: backendArtifact.properties.?circuitBreaker ?? {}
  }
}

module api '../workspaces/apis/api.bicep' = {
  name: 'api-${workspaceName}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: workspace.outputs.name
    apiName: apiName
    displayName: apiDisplayName
    path: apiPath
    serviceUrl: backendArtifact.properties.url
    format: 'openapi+json'
    value: openApiContent
  }
}

module apiPolicy '../workspaces/apis/apiPolicy.bicep' = {
  name: 'apipol-${workspaceName}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: workspace.outputs.name
    apiName: api.outputs.name
    policyValue: apiPolicyXml
  }
  dependsOn: [
    backend
    namedValueModules
  ]
}

module group '../workspaces/groups/group.bicep' = {
  name: 'grp-${workspaceName}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: workspace.outputs.name
    groupName: groupArtifact.name
    displayName: groupArtifact.properties.displayName
    groupDescription: groupArtifact.properties.?description ?? ''
  }
}

module product '../workspaces/products/product.bicep' = {
  name: 'prd-${workspaceName}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: workspace.outputs.name
    productName: productArtifact.name
    displayName: productArtifact.properties.displayName
    productDescription: productArtifact.properties.?description ?? ''
    terms: productArtifact.properties.?terms ?? ''
    subscriptionsLimit: productArtifact.properties.?subscriptionsLimit ?? 1
  }
}

module productApiLink '../workspaces/products/productApiLink.bicep' = {
  name: 'prdapi-${workspaceName}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: workspace.outputs.name
    productName: product.outputs.name
    apiName: api.outputs.name
  }
}

module productGroupLink '../workspaces/products/productGroupLink.bicep' = {
  name: 'prdgrp-${workspaceName}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: workspace.outputs.name
    productName: product.outputs.name
    groupName: group.outputs.name
  }
}

module productPolicy '../workspaces/products/productPolicy.bicep' = {
  name: 'prdpol-${workspaceName}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: workspace.outputs.name
    productName: product.outputs.name
    policyValue: productPolicyXml
  }
}

module subscription '../workspaces/subscriptions/subscription.bicep' = {
  name: 'sub-${workspaceName}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: workspace.outputs.name
    subscriptionName: subscriptionArtifact.name
    displayName: subscriptionArtifact.properties.displayName
    scope: product.outputs.id
  }
  dependsOn: [
    productApiLink
  ]
}

module gatewayLogs '../workspaces/diagnostics/gatewayLogs.bicep' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'logs-${workspaceName}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: workspace.outputs.name
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

output workspaceId string = workspace.outputs.id
