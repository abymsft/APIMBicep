@description('Name of the existing API Management service')
param apimServiceName string

@description('Name of the existing workspace')
param workspaceName string

@description('Certificate resource name')
@minLength(1)
@maxLength(80)
param certificateName string

@description('Key Vault secret identifier of the certificate')
#disable-next-line secure-secrets-in-params // URI, not a secret value
param keyVaultSecretIdentifier string

@description('Client ID of the user-assigned identity used to read Key Vault; leave empty for system-assigned')
param identityClientId string = ''

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource certificate 'Microsoft.ApiManagement/service/workspaces/certificates@2025-09-01-preview' = {
  parent: workspace
  name: certificateName
  properties: {
    keyVault: {
      secretIdentifier: keyVaultSecretIdentifier
      identityClientId: empty(identityClientId) ? null : identityClientId
    }
  }
}

output id string = certificate.id
