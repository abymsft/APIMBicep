# Assign access to APIM workspaces (Azure RBAC)

Creating a workspace (see [workspaces.bicep](../infra/workspaces.bicep)) does **not** give anyone permission to manage it. This guide explains how to give a team access to a workspace using Azure role-based access control (RBAC).

## Table of contents

1. [The key idea](#the-key-idea)
2. [Scopes: where a role is assigned](#scopes-where-a-role-is-assigned)
3. [Built-in workspace roles](#built-in-workspace-roles)
4. [Which roles to give which person](#which-roles-to-give-which-person)
5. [Prerequisites](#prerequisites)
6. [Assign roles with Azure CLI](#assign-roles-with-azure-cli)
7. [Assign roles with Bicep](#assign-roles-with-bicep)
8. [Assign roles in the Azure portal](#assign-roles-in-the-azure-portal)
9. [Workspace gateway roles (only if you use a workspace gateway)](#workspace-gateway-roles-only-if-you-use-a-workspace-gateway)
10. [Verify the assignments](#verify-the-assignments)
11. [Remove access](#remove-access)
12. [Troubleshooting](#troubleshooting)
13. [What RBAC does not do](#what-rbac-does-not-do)

## The key idea

- A **role** is a named set of permitted actions (for example, "edit APIs in a workspace").
- A **role assignment** gives a **principal** (a Microsoft Entra user, group, or service principal) a role **at a scope** (a specific Azure resource, such as a workspace).
- Where you assign the role (the **scope**) decides which resources the permissions apply to. Permissions flow **down** the resource hierarchy: a role assigned on the APIM service also applies to every workspace inside it.
- **A workspace collaborator needs two role assignments: one on the workspace and one on the APIM service.** The workspace-scoped role grants access to the workspace's resources. The service-scoped role lets workspace resources reference a few service-level resources (for example, linking an API to a product or tagging an API).

> **Tip:** Assign roles to a Microsoft Entra **group** rather than to individual users. Adding or removing a person is then a group membership change, with no new role assignments.

## Scopes: where a role is assigned

For an APIM service named `apim-demo` and a workspace named `team-a`:

```text
/subscriptions/<subscription-id>
└── /resourceGroups/<resource-group>
    └── /providers/Microsoft.ApiManagement/service/apim-demo        ← SERVICE scope
        └── /workspaces/team-a                                       ← WORKSPACE scope
```

The scope is simply the resource ID of the resource the role applies to:

| Scope | Resource ID format |
|---|---|
| Service | `/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.ApiManagement/service/<apim-name>` |
| Workspace | `<service resource ID>/workspaces/<workspace-name>` |
| Workspace gateway (optional) | `/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.ApiManagement/gateways/<gateway-name>` |

Things to keep in mind:

- A role assigned on `team-a` does **not** apply to `team-b`.
- A role assigned at a higher scope (the service, the resource group, or the subscription) **is inherited** by every workspace below it. Someone with, for example, a service-level contributor role can manage every workspace. Workspace-level assignments isolate teams from each other only when they do not also hold broader roles.
- A **role definition** (what a role allows) and a **role assignment** (who has it, and where) are different things. Built-in role definitions are available across the whole tenant. Your assignment's `scope` is what limits where it applies.

## Built-in workspace roles

Source: [How to use role-based access control in Azure API Management](https://learn.microsoft.com/azure/api-management/api-management-role-based-access-control#built-in-workspace-roles).

| Role | Assign at | What it allows | Role ID |
|---|---|---|---|
| API Management Workspace Reader | Workspace | Read-only access to resources in the workspace | `ef1c2c96-4a77-49e8-b9a4-6179fe1d2fd2` |
| API Management Workspace API Developer | Workspace | Read everything in the workspace; create and edit APIs and related resources (API version sets, schemas, policies, named values, backends, certificates, diagnostics, loggers, tags, products, policy fragments) | `56328988-075d-4c6a-8766-d93edd6725b6` |
| API Management Workspace API Product Manager | Workspace | Read everything in the workspace; manage products, subscriptions, groups, tags, and notifications | `73c2c328-d004-4c5e-938c-35c6f5679a1f` |
| API Management Workspace Contributor | Workspace | Manage the workspace; can view, but not change, who has access to it | `0c34c906-8d99-4cb7-8bb7-33f5b0a1a799` |
| API Management Service Workspace API Developer | **Service** | Read tags and products; link APIs to products; assign tags to products and APIs | `9565a273-41b9-4368-97d2-aeb0c976a9b3` |
| API Management Service Workspace API Product Manager | **Service** | Everything the service-scoped developer role allows, plus read users and add users to groups | `d59a3e9c-6d52-4a5a-aeed-6bf3cf0e31da` |

Notes:

- The **service-scoped** roles grant only the narrow actions listed above. They do not give general APIM administration.
- The workspace-scoped roles also grant read access to role assignments and to the APIM gateway logs that the workspace can access.
- You can use a role's **name** or its **ID** in Azure CLI and Bicep. The names above are used in this guide's CLI examples; the IDs are used in the Bicep example.
- You can also use equivalent custom roles. Create one only if the built-in roles don't fit.

To see the exact permissions of a role:

```powershell
az role definition list --name 'API Management Workspace API Developer' --query '[0].permissions[0].actions' --output tsv
```

## Which roles to give which person

Microsoft's guidance is to assign **one workspace-scoped role and one service-scoped role** to each collaborator. Common pairings:

| Person | Workspace-scoped role | Service-scoped role |
|---|---|---|
| API developer (builds and edits APIs) | API Management Workspace API Developer | API Management Service Workspace API Developer |
| API product manager (publishes APIs, manages products and subscriptions) | API Management Workspace API Product Manager | API Management Service Workspace API Product Manager |
| Workspace owner or team lead (manages everything in the workspace) | API Management Workspace Contributor | API Management Service Workspace API Product Manager (suggested) |
| Read-only reviewer | API Management Workspace Reader | One of the two service-scoped roles, per Microsoft's guidance. Both include limited write actions (see above), so assign this only if that is acceptable |

The Contributor and Reader pairings above are a suggestion. Microsoft documents only that a service-scoped role is needed alongside a workspace-scoped one.

## Prerequisites

1. An APIM service on a tier that supports workspaces (Basic v2, Standard v2, Premium, or Premium v2) and a workspace already created in it.
2. The **object ID** of the group, user, or service principal to assign.
3. **Permission to create role assignments** at the scopes you're using. The easiest roles are **Owner**, **User Access Administrator**, or **Role Based Access Control Administrator** on the service (or a higher scope). **Contributor does not allow assigning roles.**
4. [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), signed in with `az login` to the correct subscription.

Find the object ID of a principal:

```powershell
# Group
az ad group show --group 'Team A API Developers' --query id --output tsv

# User
az ad user show --id 'user@contoso.com' --query id --output tsv

# Service principal
az ad sp show --id '<app-id-or-object-id>' --query id --output tsv
```

## Assign roles with Azure CLI

The commands below use PowerShell syntax (line continuation with a backtick). In Bash, replace `` ` `` with `\` and write variables as `VAR=value` and `$VAR`.

### Example: give a team API developer access to workspace `team-a`

```powershell
az account set --subscription '<subscription-id>'

$subscriptionId = az account show --query id --output tsv
$resourceGroup  = '<resource-group>'
$apimName       = 'apim-demo'
$workspaceName  = 'team-a'
$principalId    = '<object-id-of-group-user-or-service-principal>'
$principalType  = 'Group'   # Group | User | ServicePrincipal

# Scope = the resource ID the role applies to
$serviceScope   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ApiManagement/service/$apimName"
$workspaceScope = "$serviceScope/workspaces/$workspaceName"

# Check the scopes before assigning anything
$serviceScope
$workspaceScope

# 1. Workspace-scoped role: applies to team-a only
az role assignment create `
    --assignee-object-id $principalId `
    --assignee-principal-type $principalType `
    --role 'API Management Workspace API Developer' `
    --scope $workspaceScope

# 2. Service-scoped role: limited service-level actions needed by workspace collaborators
az role assignment create `
    --assignee-object-id $principalId `
    --assignee-principal-type $principalType `
    --role 'API Management Service Workspace API Developer' `
    --scope $serviceScope
```

How to read it:

| Part | Meaning |
|---|---|
| `--assignee-object-id` | The Microsoft Entra object ID of who receives the role. |
| `--assignee-principal-type` | `Group`, `User`, or `ServicePrincipal`. Setting it avoids failures when a newly created principal hasn't replicated yet. |
| `--role` | The role name (or role ID). |
| `--scope` | **Where** the role applies. This is the part that differs between the two commands. |

### Example: product manager for several workspaces

```powershell
$roles = @{
    Workspace = 'API Management Workspace API Product Manager'
    Service   = 'API Management Service Workspace API Product Manager'
}

# The service-scoped role is assigned once per principal, not once per workspace.
az role assignment create --assignee-object-id $principalId --assignee-principal-type $principalType `
    --role $roles.Service --scope $serviceScope

foreach ($ws in 'team-a', 'team-b') {
    az role assignment create --assignee-object-id $principalId --assignee-principal-type $principalType `
        --role $roles.Workspace --scope "$serviceScope/workspaces/$ws"
}
```

Running `az role assignment create` for an assignment that already exists doesn't create a duplicate; the CLI reports that it already exists.

## Assign roles with Bicep

Use this if you want role assignments tracked in source control next to your workspace deployments. The workspace and service are referenced as `existing` resources, and each role assignment sets `scope` to the resource it applies to.

```bicep
targetScope = 'resourceGroup'

param apimServiceName string
param workspaceName string

@description('Object ID of the Microsoft Entra group, user, or service principal')
param principalId string

@allowed([ 'Group', 'User', 'ServicePrincipal' ])
param principalType string = 'Group'

// Built-in role IDs
var workspaceApiDeveloperRoleId = '56328988-075d-4c6a-8766-d93edd6725b6'        // workspace scope
var serviceWorkspaceApiDeveloperRoleId = '9565a273-41b9-4368-97d2-aeb0c976a9b3' // service scope

resource apim 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2025-09-01-preview' existing = {
  parent: apim
  name: workspaceName
}

resource workspaceRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: workspace // <- WORKSPACE scope
  name: guid(workspace.id, principalId, workspaceApiDeveloperRoleId)
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', workspaceApiDeveloperRoleId)
  }
}

resource serviceRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: apim // <- SERVICE scope
  name: guid(apim.id, principalId, serviceWorkspaceApiDeveloperRoleId)
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceWorkspaceApiDeveloperRoleId)
  }
}
```

Deploy it to the resource group that contains the APIM service:

```powershell
az deployment group create -g <resource-group> -f <your-file>.bicep -p apimServiceName=<apim-name> workspaceName=team-a principalId=<object-id>
```

Notes:

- The role assignment `name` must be a GUID. `guid(scope, principal, role)` keeps it stable, so redeploying doesn't create duplicates.
- The identity running the deployment needs permission to create role assignments (see [Prerequisites](#prerequisites)).
- Deploy the workspace first (for example with [workspaces.bicep](../infra/workspaces.bicep)); this template only references it.

## Assign roles in the Azure portal

1. **Service-scoped role:** open your APIM instance → **Access control (IAM)** → **+ Add** → **Add role assignment**. Choose **API Management Service Workspace API Developer** (or **Product Manager**), then select the members.
2. **Workspace-scoped role:** in the same APIM instance, under **APIs**, select **Workspaces** → your workspace → **Access control (IAM)** → **+ Add** → **Add role assignment**. Choose one of the four workspace-scoped roles, then select the members.

## Workspace gateway roles (only if you use a workspace gateway)

A workspace can be served by the service's default managed gateway or by a separate **workspace gateway** resource. The templates in this repository don't create a workspace gateway. If you associate a workspace with one, also assign an Azure-provided role at the **gateway's** scope:

| Role | Allows |
|---|---|
| Reader | View the gateway's settings (the minimum) |
| Contributor or Owner | Manage the gateway's settings, including scaling |

```powershell
$gatewayScope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ApiManagement/gateways/<gateway-name>"

az role assignment create `
    --assignee-object-id $principalId `
    --assignee-principal-type $principalType `
    --role 'Reader' `
    --scope $gatewayScope
```

## Verify the assignments

**What does this principal have, at each scope, including inherited roles?**

```powershell
az role assignment list `
    --assignee $principalId `
    --scope $workspaceScope `
    --include-inherited `
    --query "[].{Role:roleDefinitionName, AssignedAt:scope}" `
    --output table
```

Read the `AssignedAt` column to see where each role comes from: the workspace, the service, the resource group, or the subscription. Roles in `AssignedAt` above the workspace are inherited.

**Who has access to this workspace?**

```powershell
az role assignment list `
    --scope $workspaceScope `
    --include-inherited `
    --query "[].{Principal:principalName, Type:principalType, Role:roleDefinitionName, AssignedAt:scope}" `
    --output table
```

**Test as the user:** sign in as a member of the group (for example in a private browser window) and confirm they can open the workspace in the Azure portal, edit an API, and link it to a product.

Role assignments can take a few minutes to take effect. If someone was already signed in, they may need to sign out and back in.

## Remove access

```powershell
az role assignment delete `
    --assignee $principalId `
    --role 'API Management Workspace API Developer' `
    --scope $workspaceScope

az role assignment delete `
    --assignee $principalId `
    --role 'API Management Service Workspace API Developer' `
    --scope $serviceScope
```

Remove the service-scoped role only when the principal no longer needs access to **any** workspace in the service. After you delete a workspace, check for leftover role assignments and remove them.

## What RBAC does not do

- **It doesn't create the workspace or its contents.** See [workspaces.bicep](../infra/workspaces.bicep) and [sampleWorkspaces.bicep](../infra/sampleWorkspaces.bicep).
- **It doesn't control who can call your APIs.** RBAC governs who can *manage* APIM resources. Callers are controlled by subscription keys, token validation, and other API policies.
- **It doesn't automatically give workspace teams permissions.** Every team needs the role assignments described here.
- **It doesn't isolate workspaces from broader roles.** Roles inherited from the service, resource group, or subscription still apply.
