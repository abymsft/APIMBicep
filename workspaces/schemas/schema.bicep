@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Global schema resource name')
@minLength(1)
@maxLength(80)
param schemaName string

@description('Schema document content as a string')
param schemaValue string

param schemaDescription string = ''

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource schema 'Microsoft.ApiManagement/service/workspaces/schemas@2025-09-01-preview' = {
  parent: workspace
  name: schemaName
  properties: {
    schemaType: 'json'
    description: schemaDescription
    value: schemaValue
  }
}

output id string = schema.id
