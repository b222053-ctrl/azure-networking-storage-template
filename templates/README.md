# ARM Templates

This directory contains Azure Resource Manager (ARM) templates for deploying the Azure Networking and Storage infrastructure.

## Templates Overview

| Template | Description |
|----------|-------------|
| [vnet-template.json](vnet-template.json) | Virtual Network with Web and Database subnets |
| [vnet-parameters.json](vnet-parameters.json) | Parameters file for VNet template |
| [storage-template.json](storage-template.json) | Storage Account with private endpoint |
| [storage-parameters.json](storage-parameters.json) | Parameters file for Storage template |
| [complete-deployment.json](complete-deployment.json) | Combined template for full infrastructure |

## Quick Start

### Deploy Complete Infrastructure

```bash
# Create resource group
az group create --name rg-azure-networking-demo --location eastus

# Deploy complete infrastructure
az deployment group create \
  --resource-group rg-azure-networking-demo \
  --template-file complete-deployment.json \
  --parameters storageAccountName=stsecureapp$(date +%s | tail -c 5)
```

### Deploy Individual Components

#### VNet Only

```bash
az deployment group create \
  --resource-group rg-azure-networking-demo \
  --template-file vnet-template.json \
  --parameters vnet-parameters.json
```

#### Storage Account Only

> **Note**: VNet must exist before deploying storage with private endpoint.

```bash
az deployment group create \
  --resource-group rg-azure-networking-demo \
  --template-file storage-template.json \
  --parameters storage-parameters.json
```

## Template Details

### vnet-template.json

Deploys:
- Virtual Network with custom address space
- Database subnet with Microsoft.Storage service endpoint
- Web subnet with Network Security Group
- NSG with HTTPS (443) allow rule

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| vnetName | string | vnet-secure-app | Name of the VNet |
| location | string | resourceGroup().location | Azure region |
| vnetAddressPrefix | string | 10.0.0.0/16 | VNet address space |
| databaseSubnetName | string | snet-database | Database subnet name |
| databaseSubnetPrefix | string | 10.0.0.0/27 | Database subnet CIDR |
| webSubnetName | string | snet-web | Web subnet name |
| webSubnetPrefix | string | 10.0.1.0/27 | Web subnet CIDR |
| enableStorageServiceEndpoint | bool | true | Enable storage endpoint |
| tags | object | {...} | Resource tags |

#### Outputs

- `vnetId`: Resource ID of the VNet
- `vnetName`: Name of the VNet
- `databaseSubnetId`: Resource ID of database subnet
- `webSubnetId`: Resource ID of web subnet
- `nsgId`: Resource ID of the NSG

### storage-template.json

Deploys:
- Storage Account (StorageV2)
- Private Endpoint (optional)
- Private DNS Zone and VNet link (optional)
- Encryption with Microsoft-managed keys

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| storageAccountName | string | (required) | Globally unique storage name |
| location | string | resourceGroup().location | Azure region |
| storageAccountSku | string | Standard_LRS | Storage SKU |
| storageAccountKind | string | StorageV2 | Storage type |
| accessTier | string | Hot | Blob access tier |
| enableHttpsTrafficOnly | bool | true | Require HTTPS |
| minimumTlsVersion | string | TLS1_2 | Minimum TLS version |
| allowBlobPublicAccess | bool | false | Allow public blob access |
| publicNetworkAccess | string | Disabled | Public network access |
| defaultNetworkAction | string | Deny | Default network rule |
| virtualNetworkName | string | vnet-secure-app | VNet for private endpoint |
| subnetName | string | snet-database | Subnet for private endpoint |
| createPrivateEndpoint | bool | true | Create private endpoint |
| createPrivateDnsZone | bool | true | Create private DNS zone |
| tags | object | {...} | Resource tags |

#### Outputs

- `storageAccountId`: Resource ID of storage account
- `storageAccountName`: Name of storage account
- `primaryBlobEndpoint`: Blob service endpoint URL
- `privateEndpointId`: Resource ID of private endpoint

### complete-deployment.json

Combined template that deploys all resources in the correct order with proper dependencies.

#### Resources Created

1. Network Security Group (nsg-snet-web)
2. Virtual Network (vnet-secure-app)
   - Database subnet with service endpoint
   - Web subnet with NSG
3. Storage Account (user-specified name)
4. Private DNS Zone (privatelink.blob.core.windows.net)
5. Private DNS Zone VNet Link
6. Private Endpoint
7. Private DNS Zone Group

#### Key Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| storageAccountName | string | (required) | Must be globally unique |
| All VNet parameters | various | defaults | See vnet-template |
| createPrivateEndpoint | bool | true | Deploy private endpoint |

## Deployment Methods

### Using Azure CLI

```bash
# Validate template before deployment
az deployment group validate \
  --resource-group rg-azure-networking-demo \
  --template-file complete-deployment.json \
  --parameters storageAccountName=mystorageaccount

# Deploy with what-if (preview changes)
az deployment group what-if \
  --resource-group rg-azure-networking-demo \
  --template-file complete-deployment.json \
  --parameters storageAccountName=mystorageaccount

# Deploy
az deployment group create \
  --resource-group rg-azure-networking-demo \
  --template-file complete-deployment.json \
  --parameters storageAccountName=mystorageaccount
```

### Using Azure PowerShell

```powershell
# Validate
Test-AzResourceGroupDeployment `
  -ResourceGroupName rg-azure-networking-demo `
  -TemplateFile complete-deployment.json `
  -storageAccountName mystorageaccount

# Deploy
New-AzResourceGroupDeployment `
  -ResourceGroupName rg-azure-networking-demo `
  -TemplateFile complete-deployment.json `
  -storageAccountName mystorageaccount
```

### Using Azure Portal

1. Navigate to "Deploy a custom template"
2. Click "Build your own template in the editor"
3. Upload or paste the template JSON
4. Click "Save"
5. Fill in parameters
6. Click "Review + create"

## Parameter Customization

### Using Parameter Files

```bash
# Create custom parameter file
cat > my-parameters.json << 'EOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": {
      "value": "mystorage12345"
    },
    "vnetAddressPrefix": {
      "value": "172.16.0.0/16"
    },
    "tags": {
      "value": {
        "Environment": "Production",
        "CostCenter": "IT"
      }
    }
  }
}
EOF

# Deploy with parameter file
az deployment group create \
  --resource-group rg-azure-networking-demo \
  --template-file complete-deployment.json \
  --parameters @my-parameters.json
```

### Inline Parameters

```bash
az deployment group create \
  --resource-group rg-azure-networking-demo \
  --template-file complete-deployment.json \
  --parameters \
    storageAccountName=mystorage12345 \
    vnetAddressPrefix=172.16.0.0/16 \
    createPrivateEndpoint=false
```

## Troubleshooting

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Storage account name already taken | Name must be globally unique | Use a different name |
| Subnet not found | VNet doesn't exist | Deploy VNet first or use complete-deployment |
| Private endpoint failed | Subnet policies | Ensure privateEndpointNetworkPolicies is Disabled |
| Validation error | Invalid JSON | Check syntax with a JSON validator |

### Validate Template

```bash
# Check template syntax
az deployment group validate \
  --resource-group rg-azure-networking-demo \
  --template-file complete-deployment.json \
  --parameters storageAccountName=test12345
```

### View Deployment History

```bash
# List deployments
az deployment group list \
  --resource-group rg-azure-networking-demo \
  --output table

# Get deployment details
az deployment group show \
  --resource-group rg-azure-networking-demo \
  --name <deployment-name>
```

## Best Practices

1. **Always validate** templates before deployment
2. **Use what-if** to preview changes
3. **Store templates** in source control
4. **Parameterize** environment-specific values
5. **Use Template Specs** for sharing and versioning
6. **Tag resources** for organization and cost tracking

## Additional Resources

- [ARM Template Documentation](https://docs.microsoft.com/azure/azure-resource-manager/templates/)
- [ARM Template Reference](https://docs.microsoft.com/azure/templates/)
- [Template Functions](https://docs.microsoft.com/azure/azure-resource-manager/templates/template-functions)
