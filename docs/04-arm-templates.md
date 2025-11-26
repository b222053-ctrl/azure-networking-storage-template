# 04 - ARM Templates

## Overview

This guide introduces Azure Resource Manager (ARM) templates for automating infrastructure deployment using Infrastructure as Code (IaC).

## Table of Contents

- [What are ARM Templates?](#what-are-arm-templates)
- [Template Structure](#template-structure)
- [Exporting Templates from Azure Portal](#exporting-templates-from-azure-portal)
- [Creating Custom Templates](#creating-custom-templates)
- [Template Specs](#template-specs)
- [Deployment Methods](#deployment-methods)
- [Benefits of IaC](#benefits-of-iac)

## What are ARM Templates?

ARM templates are JSON files that define the infrastructure and configuration for your Azure resources. They enable:

- **Declarative Deployment**: Describe the desired state, Azure handles the rest
- **Idempotent Operations**: Deploy multiple times with the same result
- **Orchestration**: Azure deploys resources in the correct order
- **Repeatable Deployments**: Same template, different environments

### Template Types

| Type | Format | Use Case |
|------|--------|----------|
| **ARM Templates** | JSON | Traditional, well-supported |
| **Bicep** | DSL | Simpler syntax, compiles to ARM |
| **Terraform** | HCL | Multi-cloud support |

This guide focuses on ARM templates in JSON format.

## Template Structure

### Basic Template Structure

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": { },
  "variables": { },
  "resources": [ ],
  "outputs": { }
}
```

### Section Breakdown

#### 1. Schema and Content Version

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0"
}
```

- **$schema**: Specifies the template language version
- **contentVersion**: Your version number for the template

#### 2. Parameters

Parameters allow customization at deployment time:

```json
"parameters": {
  "storageAccountName": {
    "type": "string",
    "metadata": {
      "description": "Name of the storage account"
    },
    "minLength": 3,
    "maxLength": 24
  },
  "location": {
    "type": "string",
    "defaultValue": "[resourceGroup().location]",
    "metadata": {
      "description": "Location for all resources"
    }
  },
  "skuName": {
    "type": "string",
    "allowedValues": [
      "Standard_LRS",
      "Standard_GRS",
      "Standard_ZRS"
    ],
    "defaultValue": "Standard_LRS"
  }
}
```

**Parameter Types:**
- `string`, `int`, `bool`
- `array`, `object`
- `securestring`, `secureObject` (for secrets)

#### 3. Variables

Variables simplify templates by defining reusable values:

```json
"variables": {
  "vnetName": "vnet-secure-app",
  "webSubnetName": "snet-web",
  "databaseSubnetName": "snet-database",
  "nsgName": "[concat('nsg-', variables('webSubnetName'))]",
  "vnetAddressPrefix": "10.0.0.0/16",
  "webSubnetPrefix": "10.0.1.0/27",
  "databaseSubnetPrefix": "10.0.0.0/27"
}
```

**Common Functions:**
- `concat()`: Join strings
- `resourceGroup().location`: Get resource group location
- `uniqueString()`: Generate unique identifiers

#### 4. Resources

Resources define what to deploy:

```json
"resources": [
  {
    "type": "Microsoft.Network/virtualNetworks",
    "apiVersion": "2023-05-01",
    "name": "[variables('vnetName')]",
    "location": "[parameters('location')]",
    "properties": {
      "addressSpace": {
        "addressPrefixes": [
          "[variables('vnetAddressPrefix')]"
        ]
      },
      "subnets": [
        {
          "name": "[variables('webSubnetName')]",
          "properties": {
            "addressPrefix": "[variables('webSubnetPrefix')]"
          }
        }
      ]
    }
  }
]
```

**Key Properties:**
- `type`: Resource provider and type
- `apiVersion`: API version to use
- `name`: Resource name
- `location`: Azure region
- `dependsOn`: Dependencies (optional)
- `properties`: Resource-specific configuration

#### 5. Outputs

Outputs return values after deployment:

```json
"outputs": {
  "storageAccountId": {
    "type": "string",
    "value": "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName'))]"
  },
  "blobEndpoint": {
    "type": "string",
    "value": "[reference(parameters('storageAccountName')).primaryEndpoints.blob]"
  }
}
```

## Exporting Templates from Azure Portal

### Method 1: Export from Resource Group

1. Navigate to your **Resource Group**
2. Click **Export template** in the left menu
3. Review the generated template
4. Click **Download** to save locally

### Method 2: Export from Resource

1. Navigate to the specific **resource** (e.g., Storage Account)
2. Click **Export template** in the left menu
3. Download the template and parameters

### Method 3: Export During Creation

1. Fill in all settings for a new resource
2. Before clicking **Create**, click **Download a template for automation**
3. Save the template for future use

### Export Considerations

| Aspect | Description |
|--------|-------------|
| **Generated Names** | May contain hardcoded values; parameterize them |
| **Dependencies** | May need manual adjustment |
| **Sensitive Data** | Keys and secrets are not exported |
| **API Versions** | Check for latest versions |

## Creating Custom Templates

### VNet Template Example

See [templates/vnet-template.json](../templates/vnet-template.json) for a complete example.

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "vnetName": {
      "type": "string",
      "defaultValue": "vnet-secure-app"
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]"
    }
  },
  "variables": {
    "vnetAddressPrefix": "10.0.0.0/16"
  },
  "resources": [
    {
      "type": "Microsoft.Network/virtualNetworks",
      "apiVersion": "2023-05-01",
      "name": "[parameters('vnetName')]",
      "location": "[parameters('location')]",
      "properties": {
        "addressSpace": {
          "addressPrefixes": [
            "[variables('vnetAddressPrefix')]"
          ]
        }
      }
    }
  ]
}
```

### Storage Account Template Example

See [templates/storage-template.json](../templates/storage-template.json) for a complete example.

### Using Dependencies

When resources depend on each other:

```json
{
  "type": "Microsoft.Network/virtualNetworks/subnets",
  "apiVersion": "2023-05-01",
  "name": "[concat(variables('vnetName'), '/', variables('subnetName'))]",
  "dependsOn": [
    "[resourceId('Microsoft.Network/virtualNetworks', variables('vnetName'))]"
  ],
  "properties": {
    "addressPrefix": "[variables('subnetPrefix')]"
  }
}
```

## Template Specs

### What are Template Specs?

Template Specs are Azure resources that store ARM templates in Azure. They enable:

- **Versioning**: Track template changes over time
- **Sharing**: Share templates across subscriptions
- **Access Control**: RBAC for template access
- **Deployment Simplicity**: Deploy directly from Azure

### Creating a Template Spec

#### Azure CLI

```bash
# Create template spec from local file
az ts create \
  --resource-group rg-azure-networking-demo \
  --name vnet-template-spec \
  --version "1.0.0" \
  --template-file templates/vnet-template.json \
  --location eastus \
  --description "VNet with Web and Database subnets"
```

#### PowerShell

```powershell
# Create template spec
New-AzTemplateSpec `
  -ResourceGroupName "rg-azure-networking-demo" `
  -Name "vnet-template-spec" `
  -Version "1.0.0" `
  -TemplateFile "templates/vnet-template.json" `
  -Location "eastus" `
  -Description "VNet with Web and Database subnets"
```

### Deploying from Template Spec

```bash
# Get template spec resource ID
TEMPLATE_SPEC_ID=$(az ts show \
  --resource-group rg-azure-networking-demo \
  --name vnet-template-spec \
  --version "1.0.0" \
  --query id \
  --output tsv)

# Deploy from template spec
az deployment group create \
  --resource-group rg-azure-networking-demo \
  --template-spec $TEMPLATE_SPEC_ID
```

### Versioning Template Specs

```bash
# Create new version
az ts create \
  --resource-group rg-azure-networking-demo \
  --name vnet-template-spec \
  --version "1.1.0" \
  --template-file templates/vnet-template-v2.json \
  --location eastus

# List versions
az ts list \
  --resource-group rg-azure-networking-demo \
  --name vnet-template-spec \
  --output table
```

## Deployment Methods

### Method 1: Azure CLI

```bash
# Validate template
az deployment group validate \
  --resource-group rg-azure-networking-demo \
  --template-file templates/complete-deployment.json \
  --parameters templates/storage-parameters.json

# Deploy template
az deployment group create \
  --resource-group rg-azure-networking-demo \
  --template-file templates/complete-deployment.json \
  --parameters templates/storage-parameters.json \
  --name deployment-$(date +%Y%m%d-%H%M%S)
```

### Method 2: Azure PowerShell

```powershell
# Validate template
Test-AzResourceGroupDeployment `
  -ResourceGroupName "rg-azure-networking-demo" `
  -TemplateFile "templates/complete-deployment.json" `
  -TemplateParameterFile "templates/storage-parameters.json"

# Deploy template
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-azure-networking-demo" `
  -TemplateFile "templates/complete-deployment.json" `
  -TemplateParameterFile "templates/storage-parameters.json" `
  -Name "deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
```

### Method 3: Azure Portal

1. Search for **Deploy a custom template**
2. Click **Build your own template in the editor**
3. Paste your template or upload a file
4. Fill in parameters
5. Click **Review + create**

### Method 4: REST API

```bash
# Deploy using REST API
az rest --method PUT \
  --uri "https://management.azure.com/subscriptions/{subscriptionId}/resourcegroups/{resourceGroup}/providers/Microsoft.Resources/deployments/{deploymentName}?api-version=2021-04-01" \
  --body @deployment-body.json
```

## Benefits of IaC

### Why Use Infrastructure as Code?

```
┌─────────────────────────────────────────────────────────────────┐
│                    IaC Benefits                                  │
│                                                                   │
│  ┌──────────────────┐    ┌──────────────────┐                   │
│  │   Consistency    │    │   Version        │                   │
│  │   ────────────   │    │   Control        │                   │
│  │   Same config    │    │   ────────────   │                   │
│  │   every time     │    │   Track changes  │                   │
│  │                  │    │   in Git         │                   │
│  └──────────────────┘    └──────────────────┘                   │
│                                                                   │
│  ┌──────────────────┐    ┌──────────────────┐                   │
│  │   Automation     │    │   Documentation  │                   │
│  │   ────────────   │    │   ────────────   │                   │
│  │   CI/CD          │    │   Template is    │                   │
│  │   integration    │    │   the spec       │                   │
│  └──────────────────┘    └──────────────────┘                   │
│                                                                   │
│  ┌──────────────────┐    ┌──────────────────┐                   │
│  │   Reproducible   │    │   Disaster       │                   │
│  │   ────────────   │    │   Recovery       │                   │
│  │   Dev, Test,     │    │   ────────────   │                   │
│  │   Prod parity    │    │   Rebuild fast   │                   │
│  └──────────────────┘    └──────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

### Comparison: Manual vs IaC

| Aspect | Manual Deployment | Infrastructure as Code |
|--------|-------------------|----------------------|
| **Speed** | Slow, error-prone | Fast, automated |
| **Consistency** | Varies | Identical every time |
| **Documentation** | Separate docs | Self-documenting |
| **Versioning** | Difficult | Git history |
| **Collaboration** | Limited | Code reviews, PRs |
| **Recovery** | Manual recreation | Template redeployment |

### Best Practices

1. **Use Source Control**
   - Store templates in Git
   - Use branches for changes
   - Review via pull requests

2. **Parameterize Templates**
   - Avoid hardcoded values
   - Use parameter files per environment

3. **Modularize**
   - Create linked/nested templates
   - Reuse common components

4. **Validate Before Deploy**
   - Always run validation
   - Use what-if deployments

5. **Use Template Specs**
   - Store templates in Azure
   - Control access with RBAC

## Template Best Practices

### Naming Conventions

```json
"parameters": {
  "environmentName": {
    "type": "string",
    "allowedValues": ["dev", "test", "prod"]
  }
},
"variables": {
  "resourcePrefix": "[concat(parameters('environmentName'), '-', parameters('projectName'))]",
  "storageAccountName": "[concat('st', variables('resourcePrefix'))]"
}
```

### Use Conditions

```json
{
  "type": "Microsoft.Storage/storageAccounts",
  "condition": "[equals(parameters('deployStorage'), true)]",
  "apiVersion": "2023-01-01",
  "name": "[parameters('storageAccountName')]"
}
```

### Use Loops

```json
{
  "type": "Microsoft.Storage/storageAccounts",
  "apiVersion": "2023-01-01",
  "name": "[concat('storage', copyIndex())]",
  "copy": {
    "name": "storageCopy",
    "count": "[parameters('storageCount')]"
  }
}
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Template validation fails | Check JSON syntax and API versions |
| Resource not found | Verify `dependsOn` is correct |
| Deployment times out | Increase timeout or check dependencies |
| Naming conflict | Use `uniqueString()` for unique names |

## Next Steps

- Explore the [templates/](../templates/) directory for ready-to-use templates
- Proceed to [05 - Testing and Validation](05-testing-and-validation.md)

## Additional Resources

- [ARM Template Documentation](https://docs.microsoft.com/azure/azure-resource-manager/templates/)
- [ARM Template Reference](https://docs.microsoft.com/azure/templates/)
- [Template Functions](https://docs.microsoft.com/azure/azure-resource-manager/templates/template-functions)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
