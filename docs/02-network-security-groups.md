# 02 - Network Security Groups

## Overview

This guide covers creating and configuring Network Security Groups (NSGs) to secure network traffic to the Web subnet.

## Table of Contents

- [NSG Concepts](#nsg-concepts)
- [Security Rules](#security-rules)
- [Default Rules](#default-rules)
- [Creating the NSG](#creating-the-nsg)
- [Configuring Inbound Rules](#configuring-inbound-rules)
- [Associating with Subnet](#associating-with-subnet)
- [Best Practices](#best-practices)

## NSG Concepts

### What is a Network Security Group?

A Network Security Group (NSG) contains security rules that allow or deny inbound and outbound network traffic to/from Azure resources.

### Key Characteristics

| Feature | Description |
|---------|-------------|
| **Stateful** | If you allow inbound traffic, outbound response is automatically allowed |
| **Priority-based** | Rules are processed in priority order (lower number = higher priority) |
| **Association** | Can be associated with subnets or individual NICs |
| **Layered Security** | Multiple NSGs can apply to a single resource |

### NSG Evaluation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Inbound Traffic Flow                          │
│                                                                   │
│  Internet ───► Subnet NSG ───► NIC NSG ───► Virtual Machine     │
│                    │              │                               │
│                 Evaluate       Evaluate                           │
│                 Rules          Rules                              │
│                    │              │                               │
│                 Allow?         Allow?                             │
│                  Yes ────────► Yes ────────► Traffic Allowed     │
│                   │              │                                │
│                  No             No                                │
│                   ▼              ▼                                │
│              Traffic Denied  Traffic Denied                       │
└─────────────────────────────────────────────────────────────────┘
```

## Security Rules

### Rule Components

Each NSG rule consists of:

| Component | Description | Example |
|-----------|-------------|---------|
| **Name** | Unique identifier | `AllowHTTPS` |
| **Priority** | 100-4096 (lower = higher priority) | `100` |
| **Source** | IP, CIDR, service tag, or ASG | `Internet` |
| **Source Port** | Port or range | `*` |
| **Destination** | IP, CIDR, service tag, or ASG | `VirtualNetwork` |
| **Destination Port** | Port or range | `443` |
| **Protocol** | TCP, UDP, ICMP, or Any | `TCP` |
| **Action** | Allow or Deny | `Allow` |

### Service Tags

Service tags represent a group of IP address prefixes managed by Azure:

| Service Tag | Description |
|-------------|-------------|
| `Internet` | All public IP addresses |
| `VirtualNetwork` | VNet address space plus connected networks |
| `AzureLoadBalancer` | Azure's infrastructure load balancer |
| `Storage` | Azure Storage service IP ranges |

## Default Rules

Every NSG comes with three default inbound rules and three default outbound rules that cannot be deleted.

### Default Inbound Rules

| Priority | Name | Source | Destination | Port | Action |
|----------|------|--------|-------------|------|--------|
| 65000 | AllowVnetInBound | VirtualNetwork | VirtualNetwork | Any | Allow |
| 65001 | AllowAzureLoadBalancerInBound | AzureLoadBalancer | Any | Any | Allow |
| 65500 | DenyAllInBound | Any | Any | Any | Deny |

#### Rule Explanations

**AllowVnetInBound (Priority 65000)**
- Allows all traffic within the VNet
- Enables communication between VMs in the same VNet
- Essential for intra-VNet services

**AllowAzureLoadBalancerInBound (Priority 65001)**
- Allows health probes from Azure Load Balancer
- Required for load-balanced resources
- Do not block unless you understand the implications

**DenyAllInBound (Priority 65500)**
- Catches all traffic not matched by previous rules
- Acts as implicit deny
- Ensures deny-by-default security posture

### Default Outbound Rules

| Priority | Name | Source | Destination | Port | Action |
|----------|------|--------|-------------|------|--------|
| 65000 | AllowVnetOutBound | VirtualNetwork | VirtualNetwork | Any | Allow |
| 65001 | AllowInternetOutBound | Any | Internet | Any | Allow |
| 65500 | DenyAllOutBound | Any | Any | Any | Deny |

## Creating the NSG

### Option 1: Azure Portal

1. **Navigate to Network Security Groups**
   - Search for "Network security groups" in the Azure Portal
   - Click **Create**

2. **Basics Tab**
   - **Subscription**: Select your subscription
   - **Resource group**: `rg-azure-networking-demo`
   - **Name**: `nsg-web-subnet`
   - **Region**: Same as your VNet (e.g., `East US`)

3. **Review + Create**
   - Click **Create**

### Option 2: Azure CLI

```bash
# Set variables
RESOURCE_GROUP="rg-azure-networking-demo"
LOCATION="eastus"
NSG_NAME="nsg-web-subnet"

# Create NSG
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name $NSG_NAME \
  --location $LOCATION \
  --tags Environment=Demo Project=AzureNetworkingStorage
```

### Option 3: PowerShell

```powershell
# Set variables
$resourceGroup = "rg-azure-networking-demo"
$location = "eastus"
$nsgName = "nsg-web-subnet"

# Create NSG
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name $nsgName `
  -Tag @{Environment="Demo"; Project="AzureNetworkingStorage"}
```

## Configuring Inbound Rules

### Our Security Requirements

For the Web subnet, we need:
1. **Allow HTTPS (443)** from the internet
2. **Block all other inbound traffic** (use default deny rule)

### Rule: Allow HTTPS

#### Azure CLI

```bash
# Allow HTTPS from internet
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $NSG_NAME \
  --name AllowHTTPS \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes Internet \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 443
```

#### PowerShell

```powershell
# Get the NSG
$nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroup

# Add HTTPS rule
$nsg | Add-AzNetworkSecurityRuleConfig `
  -Name "AllowHTTPS" `
  -Priority 100 `
  -Direction Inbound `
  -Access Allow `
  -Protocol Tcp `
  -SourceAddressPrefix Internet `
  -SourcePortRange '*' `
  -DestinationAddressPrefix '*' `
  -DestinationPortRange 443

# Apply changes
$nsg | Set-AzNetworkSecurityGroup
```

### Rule Priority Explanation

```
┌─────────────────────────────────────────────────────────────┐
│                   Rule Processing Order                      │
│                                                               │
│  Priority 100:  AllowHTTPS (Allow TCP 443 from Internet)     │
│        ▼                                                      │
│  Priority 65000: AllowVnetInBound (Default - Allow VNet)     │
│        ▼                                                      │
│  Priority 65001: AllowAzureLoadBalancer (Default)            │
│        ▼                                                      │
│  Priority 65500: DenyAllInBound (Default - Deny Everything)  │
│                                                               │
│  ═══════════════════════════════════════════════════════     │
│  Result: Only HTTPS (443) and VNet traffic allowed           │
└─────────────────────────────────────────────────────────────┘
```

### Understanding Rule Priorities

- **100-4096**: Custom rules (we use 100 for highest priority)
- **65000-65500**: Default rules (cannot be changed)
- Lower number = Higher priority = Evaluated first

> ⚠️ **Warning**: Always leave gaps between priorities (e.g., 100, 200, 300) to allow inserting new rules later.

## Associating with Subnet

### Azure CLI

```bash
# Associate NSG with Web subnet
az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name vnet-secure-app \
  --name snet-web \
  --network-security-group $NSG_NAME
```

### PowerShell

```powershell
# Get NSG
$nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroup

# Get VNet
$vnet = Get-AzVirtualNetwork -Name "vnet-secure-app" -ResourceGroupName $resourceGroup

# Get subnet and associate NSG
$subnet = Get-AzVirtualNetworkSubnetConfig -Name "snet-web" -VirtualNetwork $vnet
$subnet.NetworkSecurityGroup = $nsg

# Apply changes
$vnet | Set-AzVirtualNetwork
```

### Verify Association

```bash
# Check subnet NSG association
az network vnet subnet show \
  --resource-group $RESOURCE_GROUP \
  --vnet-name vnet-secure-app \
  --name snet-web \
  --query networkSecurityGroup.id \
  --output tsv
```

## Viewing Effective Rules

### Azure CLI

```bash
# List all rules in the NSG
az network nsg rule list \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $NSG_NAME \
  --output table
```

### Expected Output

| Name | Priority | Direction | Access | Protocol | SourceAddress | DestPort |
|------|----------|-----------|--------|----------|---------------|----------|
| AllowHTTPS | 100 | Inbound | Allow | Tcp | Internet | 443 |

## Best Practices

### Security Recommendations

1. **Principle of Least Privilege**
   - Only allow necessary traffic
   - Be specific with source/destination addresses

2. **Use Service Tags**
   - More maintainable than IP ranges
   - Automatically updated by Azure

3. **Document Rules**
   - Use descriptive names
   - Add descriptions to complex rules

4. **Regular Auditing**
   - Review rules periodically
   - Remove unused rules

5. **Layered Security**
   - Use NSGs in combination with Azure Firewall
   - Implement defense in depth

### Naming Conventions

```
nsg-<purpose>-<subnet/resource>
Examples:
  - nsg-web-subnet
  - nsg-database-subnet
  - nsg-management-nic
```

### Common Mistakes to Avoid

| Mistake | Impact | Solution |
|---------|--------|----------|
| Too broad source addresses | Security risk | Use specific IPs or service tags |
| Overlapping priorities | Unexpected behavior | Plan priority ranges |
| Blocking Azure services | Broken functionality | Allow AzureLoadBalancer |
| No logging | Hard to troubleshoot | Enable NSG flow logs |

## Security Considerations

### What We're Protecting

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Boundaries                       │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                 Internet (Untrusted)                     ││
│  └──────────────────────────┬──────────────────────────────┘│
│                             │                                 │
│                     Only HTTPS (443)                         │
│                             ▼                                 │
│  ┌─────────────────────────────────────────────────────────┐│
│  │          Web Subnet (Protected by NSG)                   ││
│  │                                                           ││
│  │    ┌───────────────┐    ┌───────────────┐               ││
│  │    │  Web Server   │    │  Web Server   │               ││
│  │    │     VM        │    │     VM        │               ││
│  │    └───────────────┘    └───────────────┘               ││
│  └─────────────────────────────────────────────────────────┘│
│                             │                                 │
│                    VNet Traffic Allowed                      │
│                             ▼                                 │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              Database Subnet (Internal)                  ││
│  │                                                           ││
│  │    ┌───────────────┐    ┌───────────────────────┐       ││
│  │    │  Database     │    │  Private Endpoint     │       ││
│  │    │  Server       │    │  (Storage)            │       ││
│  │    └───────────────┘    └───────────────────────┘       ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Additional Hardening Options

1. **Add SSH/RDP Management Rule** (if needed)
   ```bash
   az network nsg rule create \
     --resource-group $RESOURCE_GROUP \
     --nsg-name $NSG_NAME \
     --name AllowSSHFromManagement \
     --priority 110 \
     --direction Inbound \
     --access Allow \
     --protocol Tcp \
     --source-address-prefixes "YOUR_IP_ADDRESS" \
     --destination-port-ranges 22
   ```

2. **Enable NSG Flow Logs** for traffic monitoring

3. **Use Application Security Groups** for VM grouping

## Troubleshooting

### Rule Not Working?

1. **Check priority order**
   - Is there a deny rule with lower priority (higher precedence)?

2. **Verify association**
   - Is the NSG associated with the correct subnet/NIC?

3. **Check source/destination**
   - Are the addresses correct?

4. **Use NSG Flow Logs**
   - Enable logging to see traffic patterns

### Testing Rules

```bash
# Test connectivity from a VM in the subnet
# (requires a VM deployed in the subnet)
curl -v https://example.com

# Check effective security rules for a NIC
az network nic list-effective-nsg \
  --resource-group $RESOURCE_GROUP \
  --name <nic-name>
```

## Next Steps

- Proceed to [03 - Storage Account Configuration](03-storage-account-configuration.md) to set up secure storage

## Additional Resources

- [NSG Overview](https://docs.microsoft.com/azure/virtual-network/network-security-groups-overview)
- [Service Tags](https://docs.microsoft.com/azure/virtual-network/service-tags-overview)
- [NSG Flow Logs](https://docs.microsoft.com/azure/network-watcher/network-watcher-nsg-flow-logging-overview)
