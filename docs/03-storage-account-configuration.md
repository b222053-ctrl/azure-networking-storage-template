# 03 - Storage Account Configuration

## Overview

This guide covers creating and configuring an Azure Storage Account with private endpoints, encryption, and secure network access.

## Table of Contents

- [Storage Account Basics](#storage-account-basics)
- [Creating the Storage Account](#creating-the-storage-account)
- [Replication Options](#replication-options)
- [Private Endpoint Configuration](#private-endpoint-configuration)
- [Network Access Rules](#network-access-rules)
- [Encryption Settings](#encryption-settings)
- [Best Practices](#best-practices)

## Storage Account Basics

### What is Azure Storage?

Azure Storage is Microsoft's cloud storage solution, offering:

| Service | Description | Use Case |
|---------|-------------|----------|
| **Blob Storage** | Object storage for unstructured data | Files, images, backups |
| **File Storage** | Fully managed file shares | Lift and shift applications |
| **Queue Storage** | Message queuing | Decoupling applications |
| **Table Storage** | NoSQL key-value store | Structured data |

### Storage Account Types

| Type | Supported Services | Performance |
|------|-------------------|-------------|
| **Standard general-purpose v2** | Blob, File, Queue, Table | Standard |
| **Premium block blobs** | Blob only | Premium |
| **Premium file shares** | Files only | Premium |
| **Premium page blobs** | Page blobs only | Premium |

For this project, we use **Standard general-purpose v2** (StorageV2).

## Creating the Storage Account

### Naming Requirements

- 3-24 characters
- Lowercase letters and numbers only
- Must be globally unique

### Option 1: Azure Portal

1. **Navigate to Storage Accounts**
   - Search for "Storage accounts" in Azure Portal
   - Click **Create**

2. **Basics Tab**
   - **Subscription**: Select your subscription
   - **Resource group**: `rg-azure-networking-demo`
   - **Storage account name**: `stsecureappXXXX` (replace XXXX with unique identifier)
   - **Region**: Same as VNet (e.g., `East US`)
   - **Performance**: Standard
   - **Redundancy**: Locally-redundant storage (LRS)

3. **Advanced Tab**
   - **Enable secure transfer**: Yes (HTTPS only)
   - **Enable blob public access**: No
   - **Enable storage account key access**: Yes

4. **Networking Tab**
   - **Network access**: Disable public access and use private access
   - We'll configure private endpoints after creation

5. **Data Protection Tab**
   - Keep defaults or customize based on needs

6. **Encryption Tab**
   - **Encryption type**: Microsoft-managed keys

7. **Review + Create**
   - Click **Create**

### Option 2: Azure CLI

```bash
# Set variables
RESOURCE_GROUP="rg-azure-networking-demo"
LOCATION="eastus"
STORAGE_ACCOUNT="stsecureapp$RANDOM"  # Generates unique name

# Create storage account
az storage account create \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --https-only true \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2 \
  --default-action Deny \
  --tags Environment=Demo Project=AzureNetworkingStorage

# Store the storage account name for later use
echo "Storage Account: $STORAGE_ACCOUNT"
```

### Option 3: PowerShell

```powershell
# Set variables
$resourceGroup = "rg-azure-networking-demo"
$location = "eastus"
$storageAccount = "stsecureapp" + (Get-Random -Maximum 9999)

# Create storage account
$storage = New-AzStorageAccount `
  -ResourceGroupName $resourceGroup `
  -Name $storageAccount `
  -Location $location `
  -SkuName Standard_LRS `
  -Kind StorageV2 `
  -AccessTier Hot `
  -EnableHttpsTrafficOnly $true `
  -AllowBlobPublicAccess $false `
  -MinimumTlsVersion TLS1_2 `
  -Tag @{Environment="Demo"; Project="AzureNetworkingStorage"}

Write-Host "Storage Account: $storageAccount"
```

## Replication Options

### Understanding Replication

| Option | Copies | Regions | Durability (Nines) | Use Case |
|--------|--------|---------|-------------------|----------|
| **LRS** | 3 | 1 | 11 nines | Development, non-critical data |
| **ZRS** | 3 | 1 (3 zones) | 12 nines | High availability within region |
| **GRS** | 6 | 2 | 16 nines | Disaster recovery |
| **RA-GRS** | 6 | 2 | 16 nines | DR + read access to secondary |
| **GZRS** | 6 | 2 (3 zones) | 16 nines | Maximum durability |

### LRS vs GRS

```
┌─────────────────────────────────────────────────────────────────┐
│                 LRS (Locally Redundant Storage)                  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │               Primary Region (East US)                    │   │
│  │                                                            │   │
│  │   ┌─────────┐    ┌─────────┐    ┌─────────┐              │   │
│  │   │ Copy 1  │    │ Copy 2  │    │ Copy 3  │              │   │
│  │   └─────────┘    └─────────┘    └─────────┘              │   │
│  │              Same Data Center                              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  Cost: Lowest                                                     │
│  Protection: Hardware failures in single datacenter              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                 GRS (Geo-Redundant Storage)                      │
│                                                                   │
│  ┌──────────────────────┐    ┌──────────────────────┐           │
│  │   Primary Region     │    │   Secondary Region    │           │
│  │     (East US)        │    │    (West US)          │           │
│  │                      │    │                        │           │
│  │  ┌────┐ ┌────┐ ┌────┐│    │ ┌────┐ ┌────┐ ┌────┐ │           │
│  │  │ C1 │ │ C2 │ │ C3 ││───►│ │ C1 │ │ C2 │ │ C3 │ │           │
│  │  └────┘ └────┘ └────┘│Async│ └────┘ └────┘ └────┘ │           │
│  │                      │    │  (Read-only if RA-GRS)│           │
│  └──────────────────────┘    └──────────────────────┘           │
│                                                                   │
│  Cost: Higher (~2x LRS)                                          │
│  Protection: Regional outages                                    │
└─────────────────────────────────────────────────────────────────┘
```

### Choosing the Right Option

- **LRS**: Use for this demo (cost-effective)
- **GRS/RA-GRS**: Production workloads requiring disaster recovery
- **ZRS**: High availability within a single region

## Private Endpoint Configuration

### What is a Private Endpoint?

A private endpoint is a network interface that uses a private IP address from your VNet to connect to an Azure service privately.

```
┌─────────────────────────────────────────────────────────────────┐
│                    Private Endpoint Architecture                 │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Virtual Network                         │  │
│  │                                                             │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │              Database Subnet (10.0.0.0/27)           │  │  │
│  │  │                                                       │  │  │
│  │  │    ┌───────────────────────────────────────────┐    │  │  │
│  │  │    │        Private Endpoint (10.0.0.4)        │    │  │  │
│  │  │    │        pe-storage-blob                     │    │  │  │
│  │  │    └─────────────────────┬─────────────────────┘    │  │  │
│  │  │                          │                           │  │  │
│  │  └──────────────────────────┼───────────────────────────┘  │  │
│  └─────────────────────────────┼───────────────────────────────┘  │
│                                │                                   │
│                    Private Link Connection                         │
│                                │                                   │
│  ┌─────────────────────────────▼───────────────────────────────┐  │
│  │                    Storage Account                           │  │
│  │                    stsecureappXXXX                           │  │
│  │                                                               │  │
│  │    Public Endpoint: DISABLED                                 │  │
│  │    Private Endpoint: ENABLED                                 │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Create Private Endpoint

#### Azure CLI

```bash
# Get the storage account resource ID
STORAGE_ID=$(az storage account show \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --query id \
  --output tsv)

# Create private endpoint
az network private-endpoint create \
  --resource-group $RESOURCE_GROUP \
  --name pe-storage-blob \
  --vnet-name vnet-secure-app \
  --subnet snet-database \
  --private-connection-resource-id $STORAGE_ID \
  --group-id blob \
  --connection-name storage-blob-connection \
  --location $LOCATION
```

#### PowerShell

```powershell
# Get storage account
$storage = Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount

# Get subnet
$vnet = Get-AzVirtualNetwork -Name "vnet-secure-app" -ResourceGroupName $resourceGroup
$subnet = Get-AzVirtualNetworkSubnetConfig -Name "snet-database" -VirtualNetwork $vnet

# Create private link service connection
$privateEndpointConnection = New-AzPrivateLinkServiceConnection `
  -Name "storage-blob-connection" `
  -PrivateLinkServiceId $storage.Id `
  -GroupId "blob"

# Create private endpoint
$privateEndpoint = New-AzPrivateEndpoint `
  -ResourceGroupName $resourceGroup `
  -Name "pe-storage-blob" `
  -Location $location `
  -Subnet $subnet `
  -PrivateLinkServiceConnection $privateEndpointConnection
```

### Configure Private DNS Zone

For private endpoints to resolve correctly, configure a Private DNS Zone:

```bash
# Create private DNS zone
az network private-dns zone create \
  --resource-group $RESOURCE_GROUP \
  --name "privatelink.blob.core.windows.net"

# Link DNS zone to VNet
az network private-dns link vnet create \
  --resource-group $RESOURCE_GROUP \
  --zone-name "privatelink.blob.core.windows.net" \
  --name dns-link-vnet \
  --virtual-network vnet-secure-app \
  --registration-enabled false

# Create DNS record for private endpoint
PRIVATE_IP=$(az network private-endpoint show \
  --resource-group $RESOURCE_GROUP \
  --name pe-storage-blob \
  --query 'customDnsConfigs[0].ipAddresses[0]' \
  --output tsv)

az network private-dns record-set a create \
  --resource-group $RESOURCE_GROUP \
  --zone-name "privatelink.blob.core.windows.net" \
  --name $STORAGE_ACCOUNT

az network private-dns record-set a add-record \
  --resource-group $RESOURCE_GROUP \
  --zone-name "privatelink.blob.core.windows.net" \
  --record-set-name $STORAGE_ACCOUNT \
  --ipv4-address $PRIVATE_IP
```

## Network Access Rules

### Disable Public Access

```bash
# Disable public network access
az storage account update \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --public-network-access Disabled
```

### Securing Access from Database Subnet

If you need to allow access via service endpoints instead of private endpoints:

```bash
# Add virtual network rule (alternative to private endpoint)
az storage account network-rule add \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --vnet-name vnet-secure-app \
  --subnet snet-database
```

### View Network Rules

```bash
# Check network rules
az storage account show \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --query networkRuleSet \
  --output json
```

## Encryption Settings

### Encryption at Rest

Azure Storage automatically encrypts all data at rest. By default, Microsoft-managed keys are used.

#### Verify Encryption Settings

```bash
# Check encryption configuration
az storage account show \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --query encryption \
  --output json
```

Expected output:
```json
{
  "keySource": "Microsoft.Storage",
  "services": {
    "blob": {
      "enabled": true,
      "keyType": "Account",
      "lastEnabledTime": "2024-01-01T00:00:00+00:00"
    },
    "file": {
      "enabled": true,
      "keyType": "Account",
      "lastEnabledTime": "2024-01-01T00:00:00+00:00"
    }
  }
}
```

### Encryption Options

| Option | Key Management | Use Case |
|--------|----------------|----------|
| **Microsoft-managed keys** | Azure manages everything | Default, simplest option |
| **Customer-managed keys** | You manage in Key Vault | Regulatory compliance |
| **Customer-provided keys** | You provide per-request | Maximum control |

### Encryption in Transit

Ensure HTTPS-only access:

```bash
# Verify HTTPS requirement
az storage account show \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --query enableHttpsTrafficOnly \
  --output tsv
```

Should return: `true`

## Best Practices

### Security Best Practices

1. **Disable Public Access**
   ```bash
   az storage account update \
     --name $STORAGE_ACCOUNT \
     --resource-group $RESOURCE_GROUP \
     --public-network-access Disabled
   ```

2. **Use Private Endpoints**
   - Keeps traffic on Microsoft backbone
   - Eliminates exposure to public internet

3. **Enable Secure Transfer Required**
   - Already enabled in our configuration
   - Ensures all connections use HTTPS

4. **Disable Shared Key Authorization** (when using Azure AD)
   ```bash
   az storage account update \
     --name $STORAGE_ACCOUNT \
     --resource-group $RESOURCE_GROUP \
     --allow-shared-key-access false
   ```

5. **Set Minimum TLS Version**
   ```bash
   az storage account update \
     --name $STORAGE_ACCOUNT \
     --resource-group $RESOURCE_GROUP \
     --min-tls-version TLS1_2
   ```

### Monitoring and Logging

```bash
# Enable diagnostic settings (requires Log Analytics workspace)
az monitor diagnostic-settings create \
  --name "storage-diagnostics" \
  --resource $STORAGE_ID \
  --workspace <log-analytics-workspace-id> \
  --logs '[{"category":"StorageRead","enabled":true},{"category":"StorageWrite","enabled":true},{"category":"StorageDelete","enabled":true}]' \
  --metrics '[{"category":"Transaction","enabled":true}]'
```

### Cost Optimization

1. **Choose appropriate replication**
   - LRS for dev/test
   - GRS for production

2. **Use lifecycle management**
   - Move data to cooler tiers
   - Delete old data automatically

3. **Monitor usage**
   - Review storage metrics
   - Optimize based on access patterns

## Verification

### Verify Storage Account Configuration

```bash
# Show complete storage account details
az storage account show \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --output table
```

### Verify Private Endpoint

```bash
# Show private endpoint details
az network private-endpoint show \
  --resource-group $RESOURCE_GROUP \
  --name pe-storage-blob \
  --output table
```

### Test DNS Resolution (from a VM in the VNet)

```bash
# This should resolve to a private IP (10.0.0.x)
nslookup ${STORAGE_ACCOUNT}.blob.core.windows.net
```

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Access denied | Public access disabled | Use private endpoint or add network rule |
| DNS not resolving to private IP | Private DNS zone not configured | Create and link private DNS zone |
| Cannot create private endpoint | Subnet policies | Disable private endpoint network policies |
| Storage account name taken | Names are globally unique | Try a different name |

## Next Steps

- Proceed to [04 - ARM Templates](04-arm-templates.md) to learn Infrastructure as Code automation

## Additional Resources

- [Azure Storage Documentation](https://docs.microsoft.com/azure/storage/)
- [Private Endpoints](https://docs.microsoft.com/azure/storage/common/storage-private-endpoints)
- [Storage Security Guide](https://docs.microsoft.com/azure/storage/blobs/security-recommendations)
- [Encryption at Rest](https://docs.microsoft.com/azure/storage/common/storage-service-encryption)
