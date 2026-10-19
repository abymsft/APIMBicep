# APIM Workspaces with Bicep

Deploy Azure API Management (APIM) **workspaces**, and everything inside them, to an existing APIM service using Bicep and Visual Studio Code.

> **Status:** draft. Sections marked _TODO_ are placeholders to be written.

## Table of contents

1. [Overview](#overview)
2. [What are APIM workspaces?](#what-are-apim-workspaces)
3. [Supported SKUs and gateway behavior](#supported-skus-and-gateway-behavior)
4. [Repository layout](#repository-layout)
5. [Prerequisites](#prerequisites)
6. [Deploy workspaces with Bicep in VS Code](#deploy-workspaces-with-bicep-in-vs-code)
7. [Workspace module reference](#workspace-module-reference)
8. [Add your own workspace](#add-your-own-workspace)
9. [Sample workspaces](#sample-workspaces)
10. [Monitoring](#monitoring)
11. [Verify the deployment](#verify-the-deployment)
12. [Clean up](#clean-up)
13. [Troubleshooting](#troubleshooting)
14. [Contributing and license](#contributing-and-license)

## Overview

- Reusable Bicep modules in [workspaces/](workspaces) cover workspace-scoped APIM resources (APIs, backends, named values, groups, products, subscriptions, policies, diagnostics, and more).
- Entry-point templates in [infra/](infra) compose those modules into deployable workspaces.
- Sample artifacts in [samples/](samples) (petstore, jsonplaceholder, httpbin) show how to describe a workspace as JSON/XML files.
- The workflow is VS Code first: author, validate, and deploy from the editor, with the equivalent CLI commands for automation.

_TODO: add a short architecture diagram (APIM service → workspaces → APIs/products/backends)._

### Where should I start?

| I want to... | Start here |
|---|---|
| Create empty workspaces in an existing APIM service | Deploy [workspaces.bicep](infra/workspaces.bicep) with your workspace list. |
| Try the three populated sample workspaces | Deploy [sampleWorkspaces.bicep](infra/sampleWorkspaces.bicep). It creates the workspaces and their contents; no separate empty-workspace deployment is needed. |
| Build my own populated workspace | Use [sampleWorkspace.bicep](infra/sampleWorkspace.bicep) as an example of composing the reusable modules. |
| Create an APIM service first | Optionally deploy [main.bicep](infra/main.bicep) with a [workspace-supported SKU](#supported-skus-and-gateway-behavior), rather than its default `Developer` SKU. Then choose one of the workspace deployment paths above. |

The empty-workspace and sample templates are **alternative entry points, not consecutive steps**. Both target an existing APIM service; neither automatically runs [main.bicep](infra/main.bicep).

## What are APIM workspaces?

- A workspace is an isolated administrative scope inside one APIM service, so separate teams can manage their own APIs, products, backends, and policies.
- Workspace resources are scoped to the workspace and have their own RBAC.
- _TODO: link to the Microsoft Learn article on workspaces and describe the platform team and workspace team roles._

## Supported SKUs and gateway behavior

- Workspaces require a Basic v2, Standard v2, Premium, or Premium v2 APIM service.
- `serveOn` controls which gateway serves the workspace.
  - Left empty on **BasicV2**, it defaults to `workspaceAndDefault`.
  - On other SKUs it is left to the service default.
  - It can be overridden per workspace (see [workspace.bicep](workspaces/workspace.bicep)).
- _TODO: table of SKU, workspace gateway, and limits._

## Repository layout

```text
apim-workspaces/
├── azure.yaml                     # azd project definition (optional)
├── infra/
│   ├── main.bicep                 # Optional: creates the APIM service itself
│   ├── main.parameters.json       # Parameters for main.bicep
│   ├── workspaces.bicep           # Deploys a list of workspaces to an existing APIM
│   ├── sampleWorkspaces.bicep     # Deploys the three sample workspaces
│   ├── sampleWorkspaces.bicepparam
│   └── sampleWorkspace.bicep      # One full sample workspace (used by sampleWorkspaces.bicep)
├── workspaces/                    # Granular, reusable modules (one resource type per file)
└── samples/                       # JSON/XML artifacts per sample workspace
```

### How the folders relate

| Folder | Contains | Role | Required? |
|---|---|---|---|
| [workspaces/](workspaces) | Bicep modules only | **The building blocks.** Each file deploys one workspace-scoped APIM resource type. Modules are independent leaves: none calls another module. | **Yes.** Every template in `infra/` references it, so keep it next to `infra/`. |
| [samples/](samples) | JSON, XML and OpenAPI files only (no Bicep) | **Example input data**, one folder per sample workspace. | **No.** Only the sample deployment reads it. |
| [infra/](infra) | Entry-point templates | **The orchestration.** Composes modules from `workspaces/` and, for samples, feeds them data from `samples/`. | Yes (the templates you deploy). |

```text
infra/workspaces.bicep ─────────────┐
                                    ├──► workspaces/*.bicep ──► Microsoft.ApiManagement/service/workspaces/...
infra/sampleWorkspaces.bicep        │         ▲
   └─ infra/sampleWorkspace.bicep ──┘         │ parameters
        ▲                                     │
        └── loadJsonContent / loadTextContent ── samples/<name>/**
```

- **`workspaces/` is a hard dependency.** Templates use relative paths such as `'../workspaces/workspace.bicep'`, so `infra/` and `workspaces/` must stay siblings. Copying `infra/` alone, or moving either folder, breaks the build.
- **`samples/` is an optional, data-only dependency of the sample deployment.**
  - [sampleWorkspaces.bicep](infra/sampleWorkspaces.bicep) reads the files at compile time with `loadJsonContent` / `loadTextContent`, so they are embedded in the compiled ARM template. Nothing is read from `samples/` at deployment time.
  - If a referenced file is missing or malformed, `az bicep build` fails.
  - `samples/` can be deleted if you don't deploy the samples, along with `sampleWorkspaces.bicep`, `sampleWorkspace.bicep` and `sampleWorkspaces.bicepparam`.
- **Which template needs what:**

  | Template | Uses `workspaces/` | Uses `samples/` |
  |---|---|---|
  | [workspaces.bicep](infra/workspaces.bicep) | `workspace.bicep`, `diagnostics/gatewayLogs.bicep` only | No |
  | [sampleWorkspace.bicep](infra/sampleWorkspace.bicep) | Yes, many modules (workspace, API, backend, named values, group, product and links, subscription, policies, diagnostics) | No. It receives the artifacts as parameters |
  | [sampleWorkspaces.bicep](infra/sampleWorkspaces.bicep) | Indirectly, via `sampleWorkspace.bicep` | **Yes.** Loads all three sample folders |
  | [main.bicep](infra/main.bicep) | No | No (creates the APIM service only) |

- **Adding your own workspace:**
  - For an empty workspace, add an entry to the `workspaces` array of `workspaces.bicep`. No sample data is needed.
  - For a fully populated workspace, add a folder under `samples/` (or your own data folder) and wire it up like `sampleWorkspaces.bicep` does.

### Anatomy of a `samples/<name>/` folder

An artifact is an APIM configuration resource, not just a file. These files supply the definitions and policies used to configure how the workspace exposes, secures, and routes APIs.

| Path | APIM artifact type | What it means and why it is used |
|---|---|---|
| `apis/<api>/openapi.json` | API | Defines the operations and request/response contract exposed to callers through APIM. Importing OpenAPI creates the API surface that APIM fronts for a backend service. |
| `apis/<api>/policy.xml` | API policy | Defines gateway processing rules for an API, such as validating tokens, applying rate limits, transforming messages, or selecting a backend. Used to enforce behavior without changing backend code. |
| `backends/backend.json` | Backend | Defines a reusable connection to an upstream service, including its URL and settings such as circuit breakers. Policies can reference it to route requests without repeating connection settings. |
| `namedValues/namedValues.json` | Named value | Stores reusable configuration values or secrets referenced in policies as `{{name}}`. Used to centralize settings rather than hard-code them in multiple policies. |
| `groups/group.json` | Group | Organizes developers for product visibility and access management. Associating a group with a product controls which developers can discover that product in the developer portal. |
| `products/product.json`, `products/policy.xml` | Product and product policy | A product packages APIs for consumers with shared access and subscription settings. Its policy applies common gateway rules to requests made through a subscription scoped to that product. |
| `subscriptions/subscription.json` | Subscription | Provides subscription keys that callers send when subscription access is required. This sample scopes the subscription to a product, granting key-based access to its APIs; this is separate from an Azure subscription. |
| `policies/workspace.xml` | Workspace policy | Defines shared gateway rules at workspace scope. Used to apply common behavior across workspace APIs; policy inheritance is controlled with the `<base />` element at narrower scopes. |

## Prerequisites

- An Azure subscription and a resource group.
- An existing APIM service on a workspace-capable SKU in that resource group.
  - Don't have one? Deploy [infra/main.bicep](infra/main.bicep) first (_TODO: document its parameters_).
- Permissions: Contributor, or API Management Service Contributor, on the APIM service or resource group.
- Tools:
  - [Visual Studio Code](https://code.visualstudio.com/)
  - [Bicep extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)
  - [Azure Resources extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureresourcegroups) (optional, to browse deployed resources)
  - [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with Bicep (`az bicep install`)
- Optional: a Log Analytics workspace for gateway logs.

## Deploy workspaces with Bicep in VS Code

### 1. Open the repository and sign in

1. Open the repo folder in VS Code.
2. Sign in: `az login` in the integrated terminal, and/or the **Azure** panel → **Sign in**.
3. Select the subscription: `az account set --subscription <subscription-id>`.

### 2. Deploy a list of workspaces (`infra/workspaces.bicep`)

Use this for your own workspaces.

Parameters:

| Parameter | Required | Description |
|---|---|---|
| `apimServiceName` | yes | Name of the existing APIM service (must be in the target resource group) |
| `workspaces` | no | Array of `{ name, displayName, description?, serveOn? }` |
| `logAnalyticsWorkspaceId` | no | When set, creates a `GatewayLogs` diagnostic setting per workspace |

Example parameters:

```bicep
param apimServiceName = 'apim-sample-001'
param workspaces = [
  { name: 'team-a', displayName: 'Team A', description: 'APIs owned by Team A' }
  { name: 'team-b', displayName: 'Team B', serveOn: 'workspaceAndDefault' }
]
```

_TODO: ship a `workspaces.bicepparam` file and reference it here._

### 3. Deploy the sample workspaces (`infra/sampleWorkspaces.bicep`)

[sampleWorkspaces.bicepparam](infra/sampleWorkspaces.bicepparam) reads its values from environment variables:

| Variable | Default | Purpose |
|---|---|---|
| `AZURE_APIM_SERVICE_NAME` | `apim-sample-001` | Target APIM service |
| `AZURE_LOG_ANALYTICS_WORKSPACE_ID` | _(empty)_ | Optional Log Analytics resource ID |

Set them in the VS Code terminal before deploying:

```powershell
$env:AZURE_APIM_SERVICE_NAME = '<your-apim-name>'
$env:AZURE_LOG_ANALYTICS_WORKSPACE_ID = '<optional-resource-id>'
```

### 4. Deploy from VS Code

1. Open the template, for example `infra/sampleWorkspaces.bicep`.
2. Press `Ctrl+Shift+P` and run **Bicep: Deploy Bicep File**.
3. Choose the subscription and the resource group that contains the APIM service.
4. When prompted, pick the `.bicepparam` file, or enter parameter values.
5. Watch progress in the **Output** panel (Bicep) and the Azure Resources deployments view.

Tip: **Bicep: Build Parameters File** and the Bicep visualizer (**Bicep: Open Bicep Visualizer**) help you check the module graph before deploying.

### 5. Equivalent Azure CLI commands

```powershell
# Preview changes
az deployment group what-if -g <resource-group> -f infra/sampleWorkspaces.bicep -p infra/sampleWorkspaces.bicepparam

# Deploy sample workspaces
az deployment group create -g <resource-group> -f infra/sampleWorkspaces.bicep -p infra/sampleWorkspaces.bicepparam

# Deploy your own workspaces
az deployment group create -g <resource-group> -f infra/workspaces.bicep -p apimServiceName=<apim-name> -p workspaces=@my-workspaces.json
```

### 6. Validate before you deploy

- Bicep extension diagnostics (Problems panel).
- `az bicep build -f infra/workspaces.bicep`
- `az deployment group validate` and `what-if` (see above).

## Workspace module reference

Each module in [workspaces/](workspaces) deploys one workspace-scoped resource type and takes `apimServiceName` and `workspaceName`.

| Folder | Modules |
|---|---|
| `.` | `workspace.bicep` |
| `apis/` | `api`, `apiPolicy`, `apiDiagnostic`, `apiRelease`, `apiSchema`, `operation`, `operationPolicy` |
| `apiVersionSets/` | `apiVersionSet` |
| `backends/` | `backend` |
| `certificates/` | `certificate` |
| `diagnostics/` | `diagnostic`, `gatewayLogs` |
| `groups/` | `group`, `groupUser` |
| `loggers/` | `logger` |
| `namedValues/` | `namedValue` |
| `notifications/` | `notification`, `recipientEmail`, `recipientUser` |
| `policies/` | `policyFragment`, `workspacePolicy` |
| `products/` | `product`, `productApiLink`, `productGroupLink`, `productPolicy` |
| `schemas/` | `schema` |
| `subscriptions/` | `subscription` |
| `tags/` | `tag`, `tagApiLink`, `tagOperationLink`, `tagProductLink` |

_TODO: document parameters and outputs for the most-used modules._

## Add your own workspace

- _TODO:_ copy a folder under `samples/` and follow its layout (`apis/`, `backends/`, `groups/`, `namedValues/`, `policies/`, `products/`, `subscriptions/`).
- _TODO:_ wire it in with `loadJsonContent` and `loadTextContent`, as [sampleWorkspaces.bicep](infra/sampleWorkspaces.bicep) does.
- _TODO:_ guidance on composing modules directly, as [sampleWorkspace.bicep](infra/sampleWorkspace.bicep) does, and on dependency ordering.

## Sample workspaces

| Workspace | Backend | Contents |
|---|---|---|
| `petstore` | Swagger Petstore | API, backend, named values, group, product, subscription, policies |
| `jsonplaceholder` | JSONPlaceholder | same set |
| `httpbin` | httpbin | same set |

_TODO: add backend URLs and example calls._

## Monitoring

- Setting `logAnalyticsWorkspaceId` creates a `GatewayLogs` diagnostic setting for each workspace.
- _TODO: sample Kusto queries, and required APIM diagnostic and logger setup._

## Verify the deployment

- _TODO:_ Azure portal → APIM service → **Workspaces**.
- _TODO:_ `az rest` call to list workspaces.
- _TODO:_ call a sample API with the subscription key.

## Clean up

- _TODO:_ delete a workspace (`az rest --method delete`) or the deployed resources. Bicep complete mode isn't applicable to nested resources.

## Troubleshooting

- _TODO:_ SKU doesn't support workspaces.
- _TODO:_ the resource group must contain the APIM service.
- _TODO:_ authorization failures (RBAC).
- _TODO:_ the `serveOn` Bicep type warning (BCP037) and preview API version.

## Contributing and license

_TODO._
