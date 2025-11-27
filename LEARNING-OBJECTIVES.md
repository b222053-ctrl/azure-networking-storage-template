# Learning Objectives

This document outlines the key concepts, skills, and certification alignment for the Azure Networking and Storage project.

## Skills Overview

By completing this project, you will develop practical skills in:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SKILLS DEVELOPED                                    │
│                                                                               │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────┐   │
│  │      NETWORKING      │  │       STORAGE        │  │      IaC         │   │
│  │                      │  │                      │  │                  │   │
│  │  • Virtual Networks  │  │  • Storage Accounts  │  │  • ARM Templates │   │
│  │  • Subnets           │  │  • Blob Storage      │  │  • Parameters    │   │
│  │  • NSGs              │  │  • Private Endpoints │  │  • Deployments   │   │
│  │  • Service Endpoints │  │  • SAS Tokens        │  │  • Template Specs│   │
│  │  • Private DNS       │  │  • Encryption        │  │  • CLI/PowerShell│   │
│  └──────────────────────┘  └──────────────────────┘  └──────────────────┘   │
│                                                                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Key Concepts Covered

### 1. Azure Networking

#### Virtual Networks (VNets)

| Concept | What You'll Learn |
|---------|-------------------|
| Address Spaces | CIDR notation, IP planning |
| Subnets | Segmentation, reserved addresses |
| Intra-VNet Communication | Default routing between subnets |
| Service Endpoints | Secure access to Azure services |
| Private Endpoints | Private IP for Azure PaaS services |

**Hands-on Skills**:
- Create VNets via Portal, CLI, and ARM templates
- Design IP addressing schemes
- Configure subnets for different workloads
- Enable service endpoints

#### Network Security Groups (NSGs)

| Concept | What You'll Learn |
|---------|-------------------|
| Security Rules | Priority, direction, action |
| Service Tags | Internet, VirtualNetwork, AzureLoadBalancer |
| Default Rules | Built-in allow/deny rules |
| Rule Processing | Priority-based evaluation |

**Hands-on Skills**:
- Create NSGs and associate with subnets
- Write allow and deny rules
- Understand rule priority
- Troubleshoot traffic flow

### 2. Azure Storage

#### Storage Account Configuration

| Concept | What You'll Learn |
|---------|-------------------|
| Account Types | StorageV2, Blob, File |
| Replication | LRS, GRS, ZRS, RA-GRS |
| Access Tiers | Hot, Cool, Archive |
| Network Security | Firewalls, VNet rules |

**Hands-on Skills**:
- Create storage accounts with security best practices
- Configure network access rules
- Choose appropriate replication options

#### Security Features

| Concept | What You'll Learn |
|---------|-------------------|
| Encryption at Rest | Microsoft-managed vs customer keys |
| Encryption in Transit | HTTPS, TLS versions |
| SAS Tokens | Types, permissions, expiry |
| Private Endpoints | Private connectivity |

**Hands-on Skills**:
- Configure encryption settings
- Generate SAS tokens
- Set up private endpoints
- Verify security configuration

### 3. Infrastructure as Code

#### ARM Templates

| Concept | What You'll Learn |
|---------|-------------------|
| Template Structure | Schema, parameters, resources, outputs |
| Parameters | Types, defaults, constraints |
| Variables | Expressions, functions |
| Dependencies | dependsOn, implicit dependencies |

**Hands-on Skills**:
- Write ARM templates from scratch
- Use parameters for customization
- Deploy via Azure CLI
- Create Template Specs

## Practical Exercises

### Exercise 1: Network Design
- Design a VNet address space
- Calculate subnet sizes for requirements
- Plan IP allocation

### Exercise 2: Security Implementation
- Write NSG rules for a web application
- Configure private endpoints
- Enable storage encryption

### Exercise 3: Automation
- Create ARM template for VNet
- Parameterize for different environments
- Deploy with Azure CLI

### Exercise 4: Testing and Validation
- Generate SAS tokens
- Test with Azure Storage Explorer
- Verify connectivity with AzCopy

## Certification Alignment

### AZ-104: Microsoft Azure Administrator

| Exam Domain | Topics Covered |
|-------------|----------------|
| **Configure and manage virtual networking** | VNets, subnets, NSGs, service endpoints |
| **Implement and manage storage** | Storage accounts, blob storage, security |
| **Deploy and manage Azure compute resources** | ARM templates (foundational) |

**Relevant Skills Measured**:
- Configure virtual networks
- Implement Network Security Groups
- Configure Azure Storage accounts
- Secure storage accounts
- Deploy resources using ARM templates

### AZ-305: Designing Microsoft Azure Infrastructure Solutions

| Exam Domain | Topics Covered |
|-------------|----------------|
| **Design networking solutions** | VNet design, security, private connectivity |
| **Design data storage solutions** | Storage security, encryption, access |
| **Design infrastructure solutions** | IaC patterns, deployment strategies |

**Relevant Skills Measured**:
- Recommend a network connectivity solution
- Recommend a solution for secure storage
- Recommend a data storage solution

### AZ-900: Microsoft Azure Fundamentals

| Exam Domain | Topics Covered |
|-------------|----------------|
| **Core Azure services** | VNets, Storage accounts |
| **Security, privacy, and compliance** | NSGs, encryption |
| **Azure management and governance** | ARM templates |

## Skill Assessment Checklist

### Networking Skills

- [ ] I can explain VNet address spaces and subnets
- [ ] I can create and configure NSGs
- [ ] I understand rule priority and default rules
- [ ] I can enable and use service endpoints
- [ ] I can configure private endpoints
- [ ] I can troubleshoot network connectivity

### Storage Skills

- [ ] I can create storage accounts with security settings
- [ ] I understand replication options (LRS, GRS, etc.)
- [ ] I can configure network access rules
- [ ] I can generate and use SAS tokens
- [ ] I can configure private endpoint access
- [ ] I understand encryption at rest and in transit

### IaC Skills

- [ ] I can read and understand ARM templates
- [ ] I can write basic ARM templates
- [ ] I can use parameters and variables
- [ ] I can deploy templates via Azure CLI
- [ ] I can troubleshoot deployment errors
- [ ] I understand Template Specs

## Further Learning Paths

### Beginner Next Steps

1. **Azure Virtual Machines**: Deploy VMs in your VNet
2. **Azure Load Balancer**: Add load balancing to web tier
3. **Azure DNS**: Custom domain name management

### Intermediate Next Steps

1. **Azure Application Gateway**: WAF and advanced routing
2. **Azure Firewall**: Centralized network security
3. **VNet Peering**: Connect multiple VNets
4. **Azure Bastion**: Secure VM management

### Advanced Next Steps

1. **Azure Private Link Service**: Expose your services privately
2. **Azure Front Door**: Global load balancing
3. **Network Virtual Appliances**: Third-party security
4. **Hub-Spoke Architecture**: Enterprise networking patterns

## Resources for Continued Learning

### Microsoft Learn Modules

| Module | Description |
|--------|-------------|
| [Configure virtual networks](https://docs.microsoft.com/learn/modules/configure-virtual-networks/) | VNet fundamentals |
| [Configure network security groups](https://docs.microsoft.com/learn/modules/configure-network-security-groups/) | NSG deep dive |
| [Configure Azure Storage](https://docs.microsoft.com/learn/modules/configure-azure-storage/) | Storage fundamentals |
| [Deploy Azure resources using ARM templates](https://docs.microsoft.com/learn/modules/deploy-resources-arm-templates/) | ARM template basics |

### Documentation

- [Azure Networking Documentation](https://docs.microsoft.com/azure/networking/)
- [Azure Storage Documentation](https://docs.microsoft.com/azure/storage/)
- [ARM Template Reference](https://docs.microsoft.com/azure/templates/)

### Practice Environments

- [Azure Free Account](https://azure.microsoft.com/free/): 12 months of free services
- [Microsoft Learn Sandbox](https://docs.microsoft.com/learn/): Free Azure resources for modules
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/): Estimate costs

## Project Completion Certificate

After completing all documentation guides and exercises, you should be able to:

✅ Design and deploy Azure Virtual Networks  
✅ Implement network security with NSGs  
✅ Configure secure Azure Storage accounts  
✅ Use private endpoints for private connectivity  
✅ Generate and use SAS tokens  
✅ Author and deploy ARM templates  
✅ Troubleshoot common networking and storage issues  

---

**Congratulations on completing this project!** 🎉

Consider these next steps:
1. Review the [certification alignment](#certification-alignment) for exam preparation
2. Explore [further learning paths](#further-learning-paths)
3. Apply these skills to your own Azure projects
