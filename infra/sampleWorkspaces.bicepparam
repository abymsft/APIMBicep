using 'sampleWorkspaces.bicep'

param apimServiceName = readEnvironmentVariable('AZURE_APIM_SERVICE_NAME', 'apim-sample-001')

// Optional: leave empty to skip the GatewayLogs diagnostic setting
param logAnalyticsWorkspaceId = readEnvironmentVariable('AZURE_LOG_ANALYTICS_WORKSPACE_ID', '')
