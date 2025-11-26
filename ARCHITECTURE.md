# Architecture

This document provides a detailed explanation of the Azure Networking and Storage architecture implemented in this project.

## Network Topology

```
                           ┌─────────────────────────────────────────────────────────────────────┐
                           │                           INTERNET                                    │
                           └───────────────────────────────┬─────────────────────────────────────┘
                                                           │
                                                           │ HTTPS (443) Only
                                                           ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     AZURE RESOURCE GROUP                                          │
│                                  rg-azure-networking-demo                                         │
│                                                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐│
│  │                              VIRTUAL NETWORK (10.0.0.0/16)                                   ││
│  │                                     vnet-secure-app                                           ││
│  │                                                                                               ││
│  │   ┌───────────────────────────────────┐      ┌─────────────────────────────────────────────┐ ││
│  │   │        WEB SUBNET                  │      │              DATABASE SUBNET                │ ││
│  │   │        10.0.1.0/27                 │      │               10.0.0.0/27                   │ ││
│  │   │                                    │      │                                              │ ││
│  │   │  ┌──────────────────────────────┐ │      │   ┌────────────────────────────────────┐   │ ││
│  │   │  │   NETWORK SECURITY GROUP     │ │      │   │      SERVICE ENDPOINT              │   │ ││
│  │   │  │      nsg-snet-web            │ │      │   │      Microsoft.Storage             │   │ ││
│  │   │  │                              │ │      │   │                                    │   │ ││
│  │   │  │  ┌────────────────────────┐  │ │      │   │   ┌──────────────────────────┐    │   │ ││
│  │   │  │  │ Priority 100:          │  │ │      │   │   │    PRIVATE ENDPOINT      │    │   │ ││
│  │   │  │  │ Allow HTTPS (443)      │  │ │      │   │   │    pe-storage-blob       │    │   │ ││
│  │   │  │  │ from Internet          │  │ │      │   │   │    10.0.0.4              │    │   │ ││
│  │   │  │  └────────────────────────┘  │ │      │   │   └───────────┬──────────────┘    │   │ ││
│  │   │  │                              │ │      │   └───────────────┼──────────────────────┘   │ ││
│  │   │  │  ┌────────────────────────┐  │ │      │                   │                          │ ││
│  │   │  │  │ Default Rules:         │  │ │      │                   │ Private Link             │ ││
│  │   │  │  │ • AllowVnetInBound     │  │ │      │                   │ Connection               │ ││
│  │   │  │  │ • AllowAzureLB         │  │ │      │                   │                          │ ││
│  │   │  │  │ • DenyAllInBound       │  │ │      │                   │                          │ ││
│  │   │  │  └────────────────────────┘  │ │      └───────────────────┼──────────────────────────┘ ││
│  │   │  │                              │ │                          │                            ││
│  │   │  └──────────────────────────────┘ │                          │                            ││
│  │   │                                    │                          │                            ││
│  │   │   ┌────────────────────────────┐  │                          │                            ││
│  │   │   │     WEB SERVERS            │  │                          │                            ││
│  │   │   │   (Future Deployment)      │  │                          │                            ││
│  │   │   └────────────────────────────┘  │                          │                            ││
│  │   │                                    │                          │                            ││
│  │   └────────────────────────────────────┘                          │                            ││
│  │                                                                   │                            ││
│  └───────────────────────────────────────────────────────────────────┼────────────────────────────┘│
│                                                                      │                             │
│  ┌───────────────────────────────────────────────────────────────────┼────────────────────────────┐│
│  │                                      PRIVATE DNS ZONE                                          ││
│  │                            privatelink.blob.core.windows.net                                   ││
│  │                                                                   │                            ││
│  │        stsecureappXXXX.blob.core.windows.net ───────────────────►10.0.0.4                     ││
│  │                                                                                                ││
│  └────────────────────────────────────────────────────────────────────────────────────────────────┘│
│                                                                                                    │
│  ┌────────────────────────────────────────────────────────────────────────────────────────────────┐│
│  │                                      STORAGE ACCOUNT                                           ││
│  │                                     stsecureappXXXX                                            ││
│  │                                                                                                ││
│  │    ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────────────────────────┐    ││
│  │    │   BLOB SERVICE   │   │   ENCRYPTION     │   │          NETWORK RULES               │    ││
│  │    │                  │   │                  │   │                                      │    ││
│  │    │  • Containers    │   │  • At-rest       │   │  • Public Access: Disabled           │    ││
│  │    │  • Blobs         │   │  • Microsoft     │   │  • Default Action: Deny              │    ││
│  │    │                  │   │    Managed Keys  │   │  • VNet Rule: snet-database          │    ││
│  │    │                  │   │  • TLS 1.2       │   │  • Private Endpoint: Enabled         │    ││
│  │    └──────────────────┘   └──────────────────┘   └──────────────────────────────────────┘    ││
│  │                                                                                                ││
│  └────────────────────────────────────────────────────────────────────────────────────────────────┘│
│                                                                                                    │
└────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### Virtual Network (VNet)

| Property | Value |
|----------|-------|
| Name | vnet-secure-app |
| Address Space | 10.0.0.0/16 |
| Region | User-specified (default: eastus) |

The Virtual Network provides network isolation and segmentation for Azure resources.

### Subnets

#### Database Subnet

| Property | Value |
|----------|-------|
| Name | snet-database |
| Address Range | 10.0.0.0/27 (32 addresses, 27 usable) |
| Service Endpoints | Microsoft.Storage |
| Private Endpoints | Enabled |

The database subnet hosts:
- Private endpoints for secure storage access
- Service endpoints for Azure Storage
- Database servers (future deployment)

#### Web Subnet

| Property | Value |
|----------|-------|
| Name | snet-web |
| Address Range | 10.0.1.0/27 (32 addresses, 27 usable) |
| NSG | nsg-snet-web |

The web subnet hosts:
- Web application servers (future deployment)
- Protected by Network Security Group

### Network Security Group (NSG)

| Rule | Priority | Direction | Action | Port | Source |
|------|----------|-----------|--------|------|--------|
| AllowHTTPS | 100 | Inbound | Allow | 443 | Internet |
| AllowVnetInBound | 65000 | Inbound | Allow | Any | VirtualNetwork |
| AllowAzureLoadBalancer | 65001 | Inbound | Allow | Any | AzureLoadBalancer |
| DenyAllInBound | 65500 | Inbound | Deny | Any | Any |

### Storage Account

| Property | Value |
|----------|-------|
| Name | stsecureappXXXX (unique) |
| Kind | StorageV2 |
| SKU | Standard_LRS |
| Access Tier | Hot |
| Replication | Locally Redundant (LRS) |

#### Security Configuration

| Setting | Value |
|---------|-------|
| HTTPS Only | Yes |
| Minimum TLS Version | 1.2 |
| Public Blob Access | Disabled |
| Public Network Access | Disabled |
| Default Network Action | Deny |
| Encryption | Microsoft-managed keys |

### Private Endpoint

| Property | Value |
|----------|-------|
| Name | pe-stsecureappXXXX-blob |
| Target | Blob service |
| Subnet | snet-database |
| Private IP | Dynamic (10.0.0.x) |

### Private DNS Zone

| Property | Value |
|----------|-------|
| Zone Name | privatelink.blob.core.windows.net |
| VNet Link | vnet-secure-app |
| Record | stsecureappXXXX → Private Endpoint IP |

## Data Flow

### Web Traffic Flow

```
Internet → NSG (Allow 443) → Web Subnet → Web Servers
```

1. HTTPS requests arrive from the internet
2. NSG evaluates rules (Allow port 443)
3. Traffic reaches web servers in web subnet
4. Only HTTPS traffic is permitted

### Storage Access Flow

```
Database Subnet → Private Endpoint → Storage Account
```

1. Application in database subnet initiates storage request
2. DNS resolves storage URL to private endpoint IP
3. Traffic flows through private endpoint
4. Storage account processes request securely

### Private DNS Resolution

```
Application → DNS Query → Private DNS Zone → Private IP
```

1. Application requests `stsecureappXXXX.blob.core.windows.net`
2. Query goes to Azure DNS
3. Private DNS zone returns private endpoint IP (10.0.0.x)
4. Traffic stays within the VNet

## Security Boundaries

### External Boundary

- NSG controls inbound traffic from internet
- Only HTTPS (443) allowed to web subnet
- All other ports blocked by default

### Internal Boundary

- Subnets can communicate via VNet routing
- Storage accessible only via private endpoint
- No public internet access to storage

### Data Protection

- Encryption at rest (Microsoft-managed keys)
- Encryption in transit (HTTPS/TLS 1.2)
- SAS tokens for delegated access

## Scalability Considerations

### VNet Address Space

- 10.0.0.0/16 provides 65,536 addresses
- Sufficient for future subnet additions
- Can peer with other VNets

### Subnet Sizing

- /27 subnets provide 27 usable IPs each
- Can accommodate small to medium deployments
- Consider larger subnets for production

### Storage Account

- Standard tier suitable for most workloads
- Upgrade to Premium for high IOPS requirements
- Consider GRS for disaster recovery

## Best Practices Implemented

1. **Network Segmentation**: Separate subnets for different tiers
2. **Defense in Depth**: Multiple security layers (NSG + Private Endpoint)
3. **Least Privilege**: Minimal network access permissions
4. **Encryption Everywhere**: At rest and in transit
5. **Private Connectivity**: No public exposure for storage
6. **Infrastructure as Code**: Repeatable deployments via ARM templates

## Related Documentation

- [Virtual Network Setup](docs/01-virtual-network-setup.md)
- [Network Security Groups](docs/02-network-security-groups.md)
- [Storage Account Configuration](docs/03-storage-account-configuration.md)
- [ARM Templates](docs/04-arm-templates.md)
