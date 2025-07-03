// Main Bicep template for Azure API Management deployment
// This template deploys an API Management service with Developer SKU

targetScope = 'resourceGroup'

// Parameters
@description('The name of the API Management service')
@minLength(1)
@maxLength(50)
param apimServiceName string = 'apim-${uniqueString(resourceGroup().id)}'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Publisher name for the API Management service')
@maxLength(100)
param publisherName string = 'Your Organization'

@description('Publisher email for the API Management service')
@maxLength(100)
param publisherEmail string = 'admin@yourorganization.com'

@description('SKU for the API Management service')
@allowed([
  'Developer'
  'Basic'
  'Standard'
  'Premium'
  'Consumption'
])
param apimSku string = 'Developer'

@description('Capacity for the API Management service (number of units)')
param apimCapacity int = 1

@description('Environment name for resource tagging')
param environmentName string = 'dev'

@description('Resource token for naming consistency')
param resourceToken string = uniqueString(subscription().id, resourceGroup().id)

@description('Whether to automatically publish the developer portal')
param autoPublishPortal bool = true

// Variables
var tags = {
  environment: environmentName
  'azd-env-name': environmentName
  project: 'apim-bicep'
  deployedBy: 'bicep'
}

var apimName = !empty(apimServiceName) ? apimServiceName : 'apim-${resourceToken}'

// Log Analytics Workspace for monitoring
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-${resourceToken}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Application Insights for monitoring
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-${resourceToken}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// User-assigned managed identity for API Management
resource apimManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-apim-${resourceToken}'
  location: location
  tags: tags
}

// API Management service
resource apiManagementService 'Microsoft.ApiManagement/service@2024-05-01' = {
  name: apimName
  location: location
  tags: union(tags, {
    'azd-service-name': 'apim'
  })
  sku: {
    name: apimSku
    capacity: apimCapacity
  }
  identity: {
    type: 'SystemAssigned,UserAssigned'
    userAssignedIdentities: {
      '${apimManagedIdentity.id}': {}
    }
  }
  properties: {
    publisherName: publisherName
    publisherEmail: publisherEmail
    
    // Enable Application Insights for monitoring
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'false'
    }
    
    // Configure notification settings
    notificationSenderEmail: publisherEmail
    
    // Enable public network access (can be changed to 'Disabled' for private endpoints)
    publicNetworkAccess: 'Enabled'
    
    // Enable developer portal
    developerPortalStatus: 'Enabled'
    
    // API version constraint to ensure modern API versions
    apiVersionConstraint: {
      minApiVersion: '2021-08-01'
    }
  }
}

// Diagnostic settings for API Management
resource apimDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'apim-diagnostic-settings'
  scope: apiManagementService
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

// Application Insights logger for API Management
resource apimLogger 'Microsoft.ApiManagement/service/loggers@2024-05-01' = {
  parent: apiManagementService
  name: 'applicationinsights-logger'
  properties: {
    loggerType: 'applicationInsights'
    description: 'Application Insights logger for API Management'
    credentials: {
      instrumentationKey: applicationInsights.properties.InstrumentationKey
    }
  }
}

// Developer portal configuration
resource apimPortalConfig 'Microsoft.ApiManagement/service/portalconfigs@2024-05-01' = {
  parent: apiManagementService
  name: 'default'
  properties: {
    enableBasicAuth: true
    signin: {
      require: false
    }
    signup: {
      termsOfService: {
        requireConsent: false
        text: 'By using this API, you agree to the terms of service.'
      }
    }
    cors: {
      allowedOrigins: [
        '*'
      ]
    }
    csp: {
      mode: 'disabled'
      allowedSources: []
      reportUri: []
    }
  }
}

// Developer portal revision to publish the portal
resource apimPortalRevision 'Microsoft.ApiManagement/service/portalrevisions@2024-05-01' = if (autoPublishPortal) {
  parent: apiManagementService
  name: 'initial-publication'
  properties: {
    description: 'Initial developer portal publication - deployed via Bicep template'
    isCurrent: true
  }
  dependsOn: [
    apimPortalConfig
    apimGlobalPolicy
    apimLogger
  ]
}

// Global policy for API Management
resource apimGlobalPolicy 'Microsoft.ApiManagement/service/policies@2024-05-01' = {
  parent: apiManagementService
  name: 'policy'
  properties: {
    value: '''
    <policies>
      <inbound>
        <set-header name="X-Forwarded-For" exists-action="override">
          <value>@(context.Request.IpAddress)</value>
        </set-header>
        <cors allow-credentials="false">
          <allowed-origins>
            <origin>*</origin>
          </allowed-origins>
          <allowed-methods>
            <method>GET</method>
            <method>POST</method>
            <method>PUT</method>
            <method>DELETE</method>
            <method>OPTIONS</method>
          </allowed-methods>
          <allowed-headers>
            <header>*</header>
          </allowed-headers>
        </cors>
      </inbound>
      <backend>
        <forward-request />
      </backend>
      <outbound>
        <set-header name="X-Powered-By" exists-action="delete" />
        <set-header name="Server" exists-action="delete" />
      </outbound>
      <on-error>
        <set-header name="ErrorSource" exists-action="override">
          <value>@(context.Response.StatusCode + " - " + context.Response.StatusReason)</value>
        </set-header>
      </on-error>
    </policies>
    '''
    format: 'xml'
  }
}

// Output values
@description('The name of the deployed API Management service')
output apimServiceName string = apiManagementService.name

@description('The resource ID of the API Management service')
output apimServiceId string = apiManagementService.id

@description('The gateway URL of the API Management service')
output apimGatewayUrl string = apiManagementService.properties.gatewayUrl

@description('The management API URL of the API Management service')
output apimManagementUrl string = apiManagementService.properties.managementApiUrl

@description('The developer portal URL of the API Management service')
output apimDeveloperPortalUrl string = apiManagementService.properties.developerPortalUrl

@description('The publisher portal URL of the API Management service')
output apimPortalUrl string = apiManagementService.properties.portalUrl

@description('The Application Insights instrumentation key')
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('The Application Insights connection string')
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString

@description('The Log Analytics workspace ID')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

@description('The user-assigned managed identity ID')
output managedIdentityId string = apimManagedIdentity.id

@description('The user-assigned managed identity principal ID')
output managedIdentityPrincipalId string = apimManagedIdentity.properties.principalId

@description('The developer portal revision status')
output portalRevisionStatus string = autoPublishPortal ? apimPortalRevision.properties.status : 'Not published'

@description('The developer portal publication details')
output portalPublicationInfo object = autoPublishPortal ? {
  revisionName: apimPortalRevision.name
  status: apimPortalRevision.properties.status
  description: apimPortalRevision.properties.description
  isCurrent: apimPortalRevision.properties.isCurrent
} : {
  revisionName: 'Not created'
  status: 'Not published'
  description: 'Auto-publish is disabled'
  isCurrent: false
}
