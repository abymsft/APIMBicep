# Azure API Management Bicep Template

This repository contains a Bicep template for deploying Azure API Management with Developer SKU using GitHub Actions workflow.

## 🏗️ Architecture

The template deploys:

- **Azure API Management** (Developer SKU) - Main API gateway service
- **Log Analytics Workspace** - For monitoring and diagnostics
- **Application Insights** - For application performance monitoring
- **User-assigned Managed Identity** - For secure authentication
- **Diagnostic Settings** - For comprehensive logging
- **Developer Portal Configuration** - Portal settings and CORS configuration
- **Portal Revision** - Automatically publishes the developer portal (configurable)
- **Global Policies** - Security and CORS configuration

## 📋 Prerequisites

- Azure subscription
- GitHub repository
- Azure CLI (for local development)
- Azure Developer CLI (azd)

## 🚀 Quick Start

### 1. Clone the repository

```bash
git clone <your-repository-url>
cd APIMBicep
```

### 2. Set up Azure authentication

#### Option A: Service Principal (Recommended for CI/CD)

1. Create a service principal:
```bash
az ad sp create-for-rbac --name "apim-bicep-sp" --role contributor --scopes /subscriptions/<subscription-id>
```

2. Add the following secrets to your GitHub repository:
   - `AZURE_CLIENT_ID`: Application (client) ID
   - `AZURE_CLIENT_SECRET`: Client secret
   - `AZURE_TENANT_ID`: Directory (tenant) ID
   - `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
   - `AZURE_ENV_NAME`: Environment name (e.g., "dev", "prod")

#### Option B: Federated Identity (More secure)

1. Set up OpenID Connect between GitHub and Azure
2. Configure workload identity federation
3. Add the required secrets (without client secret)

### 3. Configure deployment parameters

Edit the `infra/main.parameters.json` file or set environment variables:

- `AZURE_LOCATION`: Azure region (default: eastus)
- `AZURE_PUBLISHER_NAME`: Organization name
- `AZURE_PUBLISHER_EMAIL`: Administrator email
- `AZURE_APIM_SKU`: SKU tier (Developer, Basic, Standard, Premium)
- `AZURE_APIM_CAPACITY`: Number of units
- `AZURE_AUTO_PUBLISH_PORTAL`: Auto-publish developer portal (true/false)

### 4. Deploy using Azure Developer CLI

```bash
# Initialize the environment
azd init

# Set environment variables
azd env set AZURE_LOCATION eastus
azd env set AZURE_PUBLISHER_NAME "Your Organization"
azd env set AZURE_PUBLISHER_EMAIL "admin@yourorganization.com"
azd env set AZURE_AUTO_PUBLISH_PORTAL "true"

# Deploy the infrastructure
azd provision
```

### 5. Deploy using GitHub Actions

Push your code to the `main` or `develop` branch to trigger the deployment workflow.

## 📁 Project Structure

```
APIMBicep/
├── .github/
│   └── workflows/
│       ├── deploy.yml              # Main deployment workflow
│       └── deploy-simple.yml       # Simplified deployment workflow
├── infra/
│   ├── main.bicep                  # Main Bicep template
│   └── main.parameters.json        # Parameter file
├── azure.yaml                      # Azure Developer CLI configuration
└── README.md                       # This file
```

## 🔧 Template Features

### Security
- TLS 1.2+ enforcement
- Security headers configuration
- Managed identity authentication
- Diagnostic logging enabled

### Monitoring
- Application Insights integration
- Log Analytics workspace
- Comprehensive diagnostic settings
- Custom logging policies

### API Management Configuration
- Developer portal enabled
- CORS policy configured
- Global security policies
- Modern API version constraints

### Developer Portal Publication
- **Automatic Publication**: The template automatically publishes the developer portal after deployment
- **Configurable**: Set `AZURE_AUTO_PUBLISH_PORTAL=false` to disable auto-publication
- **Portal Configuration**: Includes CORS settings, sign-in/sign-up configuration
- **Revision Tracking**: Creates a named revision for deployment tracking

## 📊 Outputs

After deployment, you'll receive:

- API Management gateway URL
- Developer portal URL
- Management API URL
- Application Insights connection details
- Managed identity information
- Portal publication status and details

## 🔍 Monitoring and Troubleshooting

### View logs
```bash
# Using Azure CLI
az monitor activity-log list --resource-group <resource-group-name>

# Using azd
azd logs
```

### Access endpoints
- **Gateway URL**: `https://<apim-name>.azure-api.net`
- **Developer Portal**: `https://<apim-name>.developer.azure-api.net`
- **Management API**: `https://<apim-name>.management.azure-api.net`

## 🛠️ Customization

### Modify SKU and Capacity
Update the parameters in `main.parameters.json`:

```json
{
  "apimSku": {
    "value": "Premium"
  },
  "apimCapacity": {
    "value": "2"
  }
}
```

### Add Custom Policies
Edit the `apimGlobalPolicy` resource in `main.bicep` to include your custom policies.

### Enable Virtual Network Integration
For Premium SKU, you can add virtual network configuration:

```bicep
virtualNetworkConfiguration: {
  subnetResourceId: '/subscriptions/.../subnets/apim-subnet'
}
virtualNetworkType: 'External'
```

### Disable Developer Portal Auto-Publication
To prevent automatic portal publication:

```json
{
  "autoPublishPortal": {
    "value": "false"
  }
}
```

Or set the environment variable:
```bash
azd env set AZURE_AUTO_PUBLISH_PORTAL "false"
```

## 🚪 Developer Portal Features

The template configures the developer portal with:

- **Automatic Publication**: Portal is published immediately after deployment
- **CORS Configuration**: Allows all origins for development (customize for production)
- **Sign-in/Sign-up**: Basic authentication enabled, terms of service configured
- **Security**: Content Security Policy (CSP) disabled for development flexibility
- **Revision Tracking**: Each deployment creates a named revision for tracking

### Manual Portal Management

After deployment, you can manage the portal using:

```bash
# Check portal status
az apim portal show --resource-group <rg-name> --service-name <apim-name>

# Publish portal manually
az apim portal publish --resource-group <rg-name> --service-name <apim-name>

# List portal revisions
az apim portal revision list --resource-group <rg-name> --service-name <apim-name>
```

## 🔒 Security Best Practices

1. **Use Managed Identity** - Enabled by default in the template
2. **Enable HTTPS only** - Configured in global policies
3. **Disable legacy TLS** - TLS 1.0 and 1.1 are disabled
4. **Monitor access** - Diagnostic settings capture all activity
5. **Use Key Vault** - For storing sensitive configuration (not included in this template)

## 💰 Cost Optimization

- **Developer SKU**: Best for development and testing (~$50/month)
- **Basic SKU**: For light production workloads (~$150/month)
- **Standard SKU**: For production workloads (~$650/month)
- **Premium SKU**: For enterprise workloads (~$2800/month)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## 📚 Resources

- [Azure API Management Documentation](https://docs.microsoft.com/azure/api-management/)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Developer CLI](https://docs.microsoft.com/azure/developer/azure-developer-cli/)
- [GitHub Actions for Azure](https://docs.microsoft.com/azure/developer/github/github-actions)

## ⚠️ Important Notes

1. **API Management deployment takes time** - Allow 30-45 minutes for initial deployment
2. **Developer SKU limitations** - No SLA, single unit only, no virtual network support
3. **Pricing** - Monitor costs, especially for higher SKUs
4. **Custom domains** - Require additional SSL certificate configuration

## 📞 Support

For issues related to:
- **Bicep template**: Open an issue in this repository
- **Azure API Management**: Contact Azure support
- **GitHub Actions**: Check GitHub Actions documentation
