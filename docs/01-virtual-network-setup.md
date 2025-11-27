# 01 - Virtual Network Setup

## Overview

This guide walks you through creating an Azure Virtual Network (VNet) with two subnets for a secure web and database architecture.

## Table of Contents

- [Understanding Virtual Networks](#understanding-virtual-networks)
- [IP Addressing Scheme](#ip-addressing-scheme)
- [Creating the Virtual Network](#creating-the-virtual-network)
- [Configuring Subnets](#configuring-subnets)
- [Service Endpoints](#service-endpoints)
- [Verification](#verification)

## Understanding Virtual Networks

### What is a Virtual Network?

An Azure Virtual Network (VNet) is the fundamental building block for your private network in Azure. VNets enable many types of Azure resources to securely communicate with each other, the internet, and on-premises networks.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Address Space** | The range of IP addresses available in your VNet (CIDR notation) |
| **Subnets** | Logical subdivisions within your VNet to segment resources |
| **Intra-VNet Communication** | Resources within the same VNet can communicate by default |
| **Network Isolation** | VNets are isolated from each other unless explicitly connected |

### Intra-VNet Communication

By default, all resources within a VNet can communicate with each other:

```
┌─────────────────────────────────────────────────────────────┐
│                    Virtual Network                           │
│                                                               │
│  ┌──────────────────┐         ┌──────────────────────────┐  │
│  │   Subnet A       │ ◄─────► │      Subnet B             │  │
│  │   (Web VMs)      │  Auto   │   (Database VMs)          │  │
│  │                  │ Allowed │                            │  │
│  └──────────────────┘         └──────────────────────────┘  │
│                                                               │
│            All resources can communicate freely               │
└─────────────────────────────────────────────────────────────┘
```

> **Note**: Use Network Security Groups (NSGs) to control traffic between subnets if needed.

## IP Addressing Scheme

For this project, we use the following addressing:

### VNet Address Space

- **VNet CIDR**: `10.0.0.0/16` (65,536 addresses)

### Subnet Configuration

| Subnet | CIDR Block | Usable IPs | Purpose |
|--------|------------|------------|---------|
| Database Subnet | `10.0.0.0/27` | 27 | Database servers, private endpoints |
| Web Subnet | `10.0.1.0/27` | 27 | Web servers, application tier |

> **Tip**: A /27 subnet provides 32 addresses, with 27 usable (Azure reserves 5 addresses per subnet).

### Reserved Addresses in Each Subnet

Azure reserves the following addresses in each subnet:
- `.0` - Network address
- `.1` - Default gateway
- `.2, .3` - Azure DNS
- `.255` - Broadcast address (for /24 and larger)

## Creating the Virtual Network

### Option 1: Azure Portal

1. **Navigate to Virtual Networks**
   - Go to [Azure Portal](https://portal.azure.com)
   - Search for "Virtual networks" in the search bar
   - Click **Create**

2. **Basics Tab**
   - **Subscription**: Select your subscription
   - **Resource group**: Create new or select existing (`rg-azure-networking-demo`)
   - **Name**: `vnet-secure-app`
   - **Region**: Select your preferred region (e.g., `East US`)

3. **IP Addresses Tab**
   - **IPv4 address space**: `10.0.0.0/16`
   - Click **Add subnet** for each subnet (see configuration below)

4. **Security Tab**
   - Leave defaults (we'll add NSG later)

5. **Review + Create**
   - Review settings and click **Create**

### Option 2: Azure CLI

```bash
# Set variables
RESOURCE_GROUP="rg-azure-networking-demo"
LOCATION="eastus"
VNET_NAME="vnet-secure-app"

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Create virtual network with address space
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --address-prefix 10.0.0.0/16 \
  --location $LOCATION \
  --tags Environment=Demo Project=AzureNetworkingStorage
```

### Option 3: PowerShell

```powershell
# Set variables
$resourceGroup = "rg-azure-networking-demo"
$location = "eastus"
$vnetName = "vnet-secure-app"

# Create resource group
New-AzResourceGroup -Name $resourceGroup -Location $location

# Create virtual network
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name $vnetName `
  -AddressPrefix "10.0.0.0/16" `
  -Tag @{Environment="Demo"; Project="AzureNetworkingStorage"}
```

## Configuring Subnets

### Create Database Subnet

#### Azure CLI

```bash
# Create database subnet with service endpoint for Storage
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name snet-database \
  --address-prefix 10.0.0.0/27 \
  --service-endpoints Microsoft.Storage
```

#### PowerShell

```powershell
# Get the VNet
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup

# Create subnet configuration
$subnetConfig = Add-AzVirtualNetworkSubnetConfig `
  -Name "snet-database" `
  -AddressPrefix "10.0.0.0/27" `
  -VirtualNetwork $vnet `
  -ServiceEndpoint "Microsoft.Storage"

# Apply the configuration
$vnet | Set-AzVirtualNetwork
```

### Create Web Subnet

#### Azure CLI

```bash
# Create web subnet
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name snet-web \
  --address-prefix 10.0.1.0/27
```

#### PowerShell

```powershell
# Get the updated VNet
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup

# Add web subnet
$subnetConfig = Add-AzVirtualNetworkSubnetConfig `
  -Name "snet-web" `
  -AddressPrefix "10.0.1.0/27" `
  -VirtualNetwork $vnet

# Apply the configuration
$vnet | Set-AzVirtualNetwork
```

## Service Endpoints

### What are Service Endpoints?

Service endpoints extend your VNet's private address space to Azure services, enabling secure access without requiring public IP addresses.

```
┌────────────────────┐          ┌────────────────────────┐
│    Your VNet       │          │    Azure Storage       │
│                    │          │                        │
│  ┌──────────────┐  │ Service  │  ┌────────────────┐   │
│  │ Database     │──┼─Endpoint─┼──│ Storage Account│   │
│  │ Subnet       │  │ (Private)│  │ (Secured)      │   │
│  └──────────────┘  │          │  └────────────────┘   │
│                    │          │                        │
└────────────────────┘          └────────────────────────┘
```

### Benefits

1. **Security**: Traffic stays on Azure backbone network
2. **Simplicity**: No NAT or gateway devices needed
3. **Performance**: Optimal routing to Azure services
4. **Control**: Can restrict Azure services to accept traffic only from specific VNets

### Enabling Service Endpoints

The database subnet has `Microsoft.Storage` service endpoint enabled, allowing it to securely access storage accounts.

```bash
# Verify service endpoint configuration
az network vnet subnet show \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name snet-database \
  --query serviceEndpoints
```

Expected output:
```json
[
  {
    "locations": ["*"],
    "provisioningState": "Succeeded",
    "service": "Microsoft.Storage"
  }
]
```

## Verification

### Verify VNet Creation

```bash
# List VNet details
az network vnet show \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --output table
```

### Verify Subnets

```bash
# List all subnets in the VNet
az network vnet subnet list \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --output table
```

Expected output:

| Name | AddressPrefix | PrivateEndpointNetworkPolicies |
|------|---------------|-------------------------------|
| snet-database | 10.0.0.0/27 | Disabled |
| snet-web | 10.0.1.0/27 | Disabled |

### Azure Portal Verification

1. Navigate to **Virtual networks** in the Azure Portal
2. Select `vnet-secure-app`
3. Click **Subnets** in the left menu
4. Verify both subnets are created with correct address ranges

## Common Issues

| Issue | Solution |
|-------|----------|
| Address space overlap | Ensure no other VNets use the same address range |
| Subnet creation fails | Verify the subnet CIDR is within the VNet address space |
| Service endpoint not showing | Refresh the portal or wait a few seconds after creation |

## Next Steps

- Proceed to [02 - Network Security Groups](02-network-security-groups.md) to configure security rules

## Additional Resources

- [Azure Virtual Network Documentation](https://docs.microsoft.com/azure/virtual-network/virtual-networks-overview)
- [IP Addressing in Azure](https://docs.microsoft.com/azure/virtual-network/public-ip-addresses)
- [Service Endpoints Overview](https://docs.microsoft.com/azure/virtual-network/virtual-network-service-endpoints-overview)
