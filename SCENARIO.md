# Business Scenario

## Overview

This document describes the business context and requirements that drive the Azure Networking and Storage architecture implemented in this project.

## Business Context

### Company Profile

**SecureApp Solutions** is a mid-sized software company developing a new cloud-native web application for enterprise customers. The application handles sensitive business data and must meet strict security and compliance requirements.

### Application Overview

The application is a three-tier architecture:

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              Users (Internet)                                │
└───────────────────────────────────┬────────────────────────────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                           Web Tier                                          │
│                                                                              │
│   • Frontend web servers                                                     │
│   • HTTPS only (SSL/TLS)                                                     │
│   • Load balanced                                                            │
└───────────────────────────────────┬──────────────────────────────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                         Application Tier                                    │
│                                                                              │
│   • API servers                                                              │
│   • Business logic                                                           │
│   • Internal only                                                            │
└───────────────────────────────────┬──────────────────────────────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                            Data Tier                                        │
│                                                                              │
│   • Database servers                                                         │
│   • Blob storage (documents, backups)                                        │
│   • Highly secured                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Business Requirements

### Security Requirements

1. **Network Isolation**
   - Production environment must be isolated in a virtual network
   - Different tiers must be in separate subnets
   - Clear security boundaries between tiers

2. **Access Control**
   - Only HTTPS traffic allowed from the internet
   - No direct internet access to data tier
   - Storage must not be publicly accessible

3. **Encryption**
   - All data encrypted at rest
   - All traffic encrypted in transit
   - Minimum TLS 1.2 for all connections

4. **Compliance**
   - Meet SOC 2 requirements
   - Support GDPR data protection
   - Audit logging enabled

### Operational Requirements

1. **Automation**
   - Infrastructure as Code for reproducibility
   - Consistent deployments across environments
   - Version-controlled configurations

2. **Cost Optimization**
   - Use appropriate service tiers
   - Leverage Azure pricing models
   - Right-size resources

3. **Maintainability**
   - Clear documentation
   - Standard naming conventions
   - Modular architecture

## Requirements Analysis

### Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-1 | Web servers must accept HTTPS connections on port 443 | High |
| FR-2 | Storage account must support blob storage for documents | High |
| FR-3 | Database subnet must access storage securely | High |
| FR-4 | Users must be able to test storage access via SAS tokens | Medium |

### Non-Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| NFR-1 | Network latency < 5ms for internal communication | High |
| NFR-2 | Storage account must be 99.9% available | High |
| NFR-3 | Deployment must complete within 15 minutes | Medium |
| NFR-4 | Infrastructure must be redeployable from templates | High |

### Security Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| SR-1 | Public internet cannot access storage directly | Critical |
| SR-2 | All data encrypted with Microsoft-managed keys | High |
| SR-3 | TLS 1.2 minimum for all connections | High |
| SR-4 | Network traffic filtered by security groups | High |

## Solution Architecture Rationale

### Why Virtual Network?

**Requirement Addressed**: Network Isolation, Security Boundaries

Azure Virtual Networks provide:
- Private IP address space for resources
- Subnet segmentation for different tiers
- Network-level isolation from other customers
- Foundation for network security controls

**Alternative Considered**: Using public IPs only
**Why Rejected**: No network isolation, higher attack surface

### Why Network Security Groups?

**Requirement Addressed**: Access Control, Traffic Filtering

NSGs provide:
- Layer 4 (TCP/UDP) filtering
- Stateful packet inspection
- Allow/Deny rules with priorities
- Logging capabilities

**Alternative Considered**: Azure Firewall
**Why Rejected**: Overkill for this scenario, higher cost

### Why Private Endpoint?

**Requirement Addressed**: Secure Storage Access, No Public Internet Access

Private Endpoints provide:
- Private IP for Azure services
- Traffic stays on Microsoft backbone
- Eliminates public internet exposure
- Service endpoint alternative for more control

**Alternative Considered**: Service Endpoints only
**Why Rejected**: Traffic still routes via public IPs internally

### Why ARM Templates?

**Requirement Addressed**: Automation, Reproducibility, Version Control

ARM Templates provide:
- Declarative infrastructure definition
- Idempotent deployments
- Parameter-based customization
- Native Azure support

**Alternative Considered**: Terraform, Bicep
**Why Rejected**: 
- Terraform: Additional tool dependency
- Bicep: ARM provides broader audience understanding

### Why LRS Replication?

**Requirement Addressed**: Cost Optimization, Appropriate Service Tier

LRS provides:
- 99.999999999% (11 nines) durability
- 3 copies within a single datacenter
- Lowest storage cost

**Alternative Considered**: GRS (Geo-Redundant Storage)
**Why Rejected**: Higher cost, demo/dev scenario doesn't require DR

## Cost Considerations

### Estimated Monthly Cost (Demo Environment)

| Resource | SKU | Estimated Cost |
|----------|-----|----------------|
| Virtual Network | N/A | Free |
| NSG | N/A | Free |
| Storage Account | Standard LRS | ~$0.018/GB |
| Private Endpoint | N/A | ~$7.30/month |
| Private DNS Zone | N/A | ~$0.50/zone |

**Total Estimated**: ~$10-15/month for minimal usage

### Cost Optimization Strategies

1. **Delete when not in use**: Use cleanup scripts
2. **Use appropriate tiers**: LRS instead of GRS
3. **Monitor usage**: Set up Azure Cost Management alerts
4. **Reserved capacity**: Consider for production

## Success Criteria

### Technical Success

- [ ] VNet deployed with correct address space
- [ ] Both subnets created with proper configuration
- [ ] NSG applied and filtering traffic correctly
- [ ] Storage account created with private endpoint
- [ ] DNS resolution returns private IP
- [ ] SAS token authentication works

### Business Success

- [ ] Infrastructure deployable via ARM templates
- [ ] Security requirements met
- [ ] Documentation complete and clear
- [ ] Cost within expected range

## Future Considerations

### Phase 2 Enhancements

1. **Add Application Gateway**: WAF protection for web tier
2. **Implement Azure Bastion**: Secure VM management
3. **Deploy Azure Monitor**: Comprehensive monitoring
4. **Add Key Vault**: Centralized secrets management

### Production Recommendations

1. **Upgrade to GRS**: For disaster recovery
2. **Add redundant regions**: Multi-region deployment
3. **Implement Azure Policy**: Governance controls
4. **Enable Microsoft Defender**: Security monitoring

## Related Documentation

- [Architecture Overview](ARCHITECTURE.md)
- [Learning Objectives](LEARNING-OBJECTIVES.md)
- [Virtual Network Setup](docs/01-virtual-network-setup.md)
