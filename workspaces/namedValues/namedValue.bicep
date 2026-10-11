@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Named value resource name')
@minLength(1)
@maxLength(80)
param namedValueName string

@description('Display name used in policies as {{displayName}}')
param displayName string

@description('Plain or secret value; ignored when keyVaultSecretIdentifier is set')
@secure()
param value string = ''

@description('Mark the value as secret')
param secret bool = false

@description('Key Vault secret identifier; makes this a Key Vault-backed named value')
#disable-next-line secure-secrets-in-params // URI, not a secret value
param keyVaultSecretIdentifier string = ''

@description('Client ID of the user-assigned identity used to read Key Vault; leave empty for system-assigned')
param identityClientId string = ''

param tags array = []

var useKeyVault = !empty(keyVaultSecretIdentifier)

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource namedValue 'Microsoft.ApiManagement/service/workspaces/namedValues@2025-09-01-preview' = {
  parent: workspace
  name: namedValueName
  properties: {
    displayName: displayName
    tags: tags
    secret: useKeyVault ? true : secret
    value: useKeyVault ? null : value
    keyVault: useKeyVault ? {
      secretIdentifier: keyVaultSecretIdentifier
      identityClientId: empty(identityClientId) ? null : identityClientId
    } : null
  }
}

output id string = namedValue.id
