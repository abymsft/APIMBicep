@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Name of the existing API')
param apiName string

@description('Schema resource name')
@minLength(1)
@maxLength(80)
param schemaName string

@description('Media type of the schema, e.g. application/vnd.oai.openapi.components+json')
param contentType string

@description('Schema document content as a string')
param schemaValue string

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

resource schema 'Microsoft.ApiManagement/service/workspaces/apis/schemas@2025-09-01-preview' = {
  parent: api
  name: schemaName
  properties: {
    contentType: contentType
    document: {
      value: schemaValue
    }
  }
}

output id string = schema.id
