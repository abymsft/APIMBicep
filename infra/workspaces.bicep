// Deploys APIM workspaces into an existing API Management service.
// The resource group of this deployment must be the one that contains the service.

targetScope = 'resourceGroup'

@description('Name of the existing API Management service (Basic v2, Standard v2, Premium or Premium v2)')
param apimServiceName string

@description('Workspaces to create. Optional per-workspace serveOn overrides the SKU-based default.')
param workspaces array = []

@description('Optional Log Analytics workspace resource ID. When set, a GatewayLogs diagnostic setting is created per workspace.')
param logAnalyticsWorkspaceId string = ''

module workspaceModules '../workspaces/workspace.bicep' = [for ws in workspaces: {
  name: 'apimws-${ws.name}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: ws.name
    displayName: ws.displayName
    workspaceDescription: ws.?description ?? ''
    serveOn: ws.?serveOn ?? ''
  }
}]

module gatewayLogs '../workspaces/diagnostics/gatewayLogs.bicep' = [for (ws, i) in workspaces: if (!empty(logAnalyticsWorkspaceId)) {
  name: 'apimws-logs-${ws.name}'
  params: {
    apimServiceName: apimServiceName
    workspaceName: workspaceModules[i].outputs.name
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}]

output workspaceIds array = [for (ws, i) in workspaces: workspaceModules[i].outputs.id]
