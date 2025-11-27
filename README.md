# Azure Networking and Storage Template

[![Azure](https://img.shields.io/badge/Azure-Networking%20%26%20Storage-0078D4?style=flat&logo=microsoft-azure)](https://azure.microsoft.com)
[![ARM Templates](https://img.shields.io/badge/Infrastructure-ARM%20Templates-blue)](https://docs.microsoft.com/azure/azure-resource-manager/templates/)

Deploy Azure Virtual Networks, Network Security Groups, and secure Storage Accounts via ARM templates with comprehensive validation scripts.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Learning Outcomes](#learning-outcomes)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)

## Overview

This project demonstrates Azure Networking and Storage fundamentals, providing hands-on experience with:

- **Virtual Networks (VNets)**: Creating isolated network environments with multiple subnets
- **Network Security Groups (NSGs)**: Implementing network-level security controls
- **Storage Accounts**: Configuring secure blob storage with encryption
- **ARM Templates**: Automating infrastructure deployment using Infrastructure as Code

### Project Objectives

1. Design and deploy a secure Azure network topology
2. Implement network security with NSGs
3. Configure storage accounts with private endpoints
4. Automate deployment using ARM templates
5. Validate connectivity and security configurations

### Topics Covered

| Topic | Description |
|-------|-------------|
| Virtual Networks | Private network isolation in Azure |
| Network Security Groups | Layer 4 firewall rules |
| Storage Accounts | Blob, File, Queue, and Table storage |
| Encryption | Data protection at rest and in transit |
| Service Endpoints | Secure connectivity to Azure services |
| ARM Templates | Infrastructure as Code |

**Estimated Time**: ~0.75 hours

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Resource Group                          │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                Virtual Network (10.0.0.0/16)               │  │
│  │                                                             │  │
│  │  ┌─────────────────────┐    ┌─────────────────────────┐   │  │
│  │  │   Database Subnet    │    │      Web Subnet          │   │  │
│  │  │    10.0.0.0/27       │    │     10.0.1.0/27          │   │  │
│  │  │                      │    │                           │   │  │
│  │  │  ┌──────────────┐   │    │   ┌─────────────────┐    │   │  │
│  │  │  │   Private    │   │    │   │      NSG        │    │   │  │
│  │  │  │   Endpoint   │   │    │   │ ─────────────── │    │   │  │
│  │  │  └──────┬───────┘   │    │   │ Allow HTTPS:443 │    │   │  │
│  │  │         │           │    │   │ Deny All Other  │    │   │  │
│  │  └─────────┼───────────┘    │   └─────────────────┘    │   │  │
│  │            │                 └─────────────────────────┘   │  │
│  └────────────┼───────────────────────────────────────────────┘  │
│               │                                                   │
│  ┌────────────▼────────────────────────────────────────────────┐ │
│  │                   Storage Account                            │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │ │
│  │  │ Blob Storage│  │ Encryption  │  │ Network Rules       │  │ │
│  │  │             │  │ (MS Keys)   │  │ (Private Access)    │  │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘  │ │
│  └──────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

For detailed architecture information, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Prerequisites

Before starting this project, ensure you have:

### Required

- **Azure Subscription**: [Create a free account](https://azure.microsoft.com/free/)
- **Azure CLI**: Version 2.40.0 or later ([Installation Guide](https://docs.microsoft.com/cli/azure/install-azure-cli))
- **Azure PowerShell** (optional): For PowerShell-based deployments ([Installation Guide](https://docs.microsoft.com/powershell/azure/install-az-ps))

### Recommended

- **Visual Studio Code**: With Azure extensions
- **Azure Storage Explorer**: For testing storage access
- **AzCopy**: For file transfer testing

### Verify Installation

```bash
# Check Azure CLI version
az --version

# Login to Azure
az login

# Set your subscription
az account set --subscription "Your-Subscription-Name"
```

## Quick Start

### Option 1: Deploy Using Azure CLI

```bash
# Clone the repository
git clone https://github.com/your-username/azure-networking-storage-template.git
cd azure-networking-storage-template

# Make scripts executable
chmod +x scripts/*.sh

# Deploy all resources
./scripts/deploy.sh
```

### Option 2: Deploy Using ARM Templates

```bash
# Create resource group
az group create --name rg-azure-networking-demo --location eastus

# Deploy complete infrastructure
az deployment group create \
  --resource-group rg-azure-networking-demo \
  --template-file templates/complete-deployment.json \
  --parameters templates/storage-parameters.json
```

### Option 3: Step-by-Step Deployment

Follow the detailed guides in the [Documentation](#documentation) section.

## Documentation

### Step-by-Step Guides

| Guide | Description |
|-------|-------------|
| [01 - Virtual Network Setup](docs/01-virtual-network-setup.md) | Create VNet with Web and Database subnets |
| [02 - Network Security Groups](docs/02-network-security-groups.md) | Configure NSG rules for Web subnet |
| [03 - Storage Account Configuration](docs/03-storage-account-configuration.md) | Set up secure storage with private endpoints |
| [04 - ARM Templates](docs/04-arm-templates.md) | Infrastructure as Code automation |
| [05 - Testing and Validation](docs/05-testing-and-validation.md) | Verify deployment with SAS, AzCopy, Storage Explorer |

### Templates

See [templates/README.md](templates/README.md) for detailed ARM template documentation.

### Additional Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Detailed architecture explanation
- [SCENARIO.md](SCENARIO.md) - Business scenario and use case
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [LEARNING-OBJECTIVES.md](LEARNING-OBJECTIVES.md) - Skills and certification alignment

## Learning Outcomes

After completing this project, you will be able to:

### Networking Skills
- ✅ Design and implement Azure Virtual Networks
- ✅ Configure subnets with appropriate IP addressing
- ✅ Create and apply Network Security Groups
- ✅ Understand inbound/outbound security rules and priorities

### Storage Skills
- ✅ Create and configure Azure Storage Accounts
- ✅ Implement private endpoints for secure access
- ✅ Configure storage encryption
- ✅ Generate and use SAS tokens

### Infrastructure as Code
- ✅ Author ARM templates
- ✅ Use parameters and variables effectively
- ✅ Deploy templates via Azure CLI
- ✅ Create Template Specs for reuse

### Certification Alignment

This project covers topics from:
- **AZ-104**: Microsoft Azure Administrator
- **AZ-305**: Designing Microsoft Azure Infrastructure Solutions
- **AZ-900**: Microsoft Azure Fundamentals

## Troubleshooting

### Quick Fixes

| Issue | Solution |
|-------|----------|
| Deployment fails | Check Azure CLI login status: `az account show` |
| Storage access denied | Verify private endpoint and network rules |
| NSG blocking traffic | Review rule priorities (lower = higher priority) |
| Template validation errors | Run `az deployment group validate` first |

For comprehensive troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Cleanup

To avoid unexpected charges, clean up resources when finished:

```bash
# Run cleanup script
./scripts/cleanup.sh

# Or manually delete resource group
az group delete --name rg-azure-networking-demo --yes --no-wait
```

## Additional Resources

### Official Documentation
- [Azure Virtual Network Documentation](https://docs.microsoft.com/azure/virtual-network/)
- [Network Security Groups](https://docs.microsoft.com/azure/virtual-network/network-security-groups-overview)
- [Azure Storage Documentation](https://docs.microsoft.com/azure/storage/)
- [ARM Template Reference](https://docs.microsoft.com/azure/templates/)

### Learning Paths
- [Microsoft Learn: Azure Fundamentals](https://docs.microsoft.com/learn/paths/azure-fundamentals/)
- [Microsoft Learn: Azure Administrator](https://docs.microsoft.com/learn/paths/az-104-administrator-prerequisites/)

### Tools
- [Azure Storage Explorer](https://azure.microsoft.com/features/storage-explorer/)
- [AzCopy](https://docs.microsoft.com/azure/storage/common/storage-use-azcopy-v10)
- [Azure Portal](https://portal.azure.com)

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: This project is for educational purposes. Review Azure pricing before deploying resources to avoid unexpected charges.
