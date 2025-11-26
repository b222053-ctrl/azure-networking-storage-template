# Troubleshooting Guide

This document provides solutions to common issues you may encounter when deploying and using the Azure Networking and Storage infrastructure.

## Table of Contents

- [Deployment Issues](#deployment-issues)
- [Network Connectivity Issues](#network-connectivity-issues)
- [Storage Access Issues](#storage-access-issues)
- [ARM Template Issues](#arm-template-issues)
- [Azure CLI Issues](#azure-cli-issues)
- [Azure Portal Tips](#azure-portal-tips)

## Deployment Issues

### Resource Group Creation Fails

**Error**: `The subscription is not registered to use namespace 'Microsoft.Network'`

**Solution**:
```bash
# Register the required resource providers
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Storage

# Check registration status
az provider show --namespace Microsoft.Network --query registrationState
```

### Storage Account Name Already Exists

**Error**: `The storage account named 'stsecureapp0001' is already taken`

**Cause**: Storage account names must be globally unique across all Azure subscriptions.

**Solution**:
```bash
# Generate a unique name with random suffix
STORAGE_NAME="stsecureapp$(date +%s | tail -c 6)"
echo "Using storage account name: $STORAGE_NAME"

# Or check availability first
az storage account check-name --name $STORAGE_NAME
```

### Deployment Timeout

**Error**: `Deployment exceeded the configured timeout`

**Solution**:
```bash
# Increase timeout for deployment
az deployment group create \
  --resource-group rg-azure-networking-demo \
  --template-file templates/complete-deployment.json \
  --parameters storageAccountName=mystorageaccount \
  --timeout 3600  # 1 hour
```

### Insufficient Permissions

**Error**: `The client does not have authorization to perform action`

**Solution**:
1. Verify your Azure role:
   ```bash
   az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv)
   ```

2. Required roles:
   - **Contributor** on the resource group, or
   - **Network Contributor** + **Storage Account Contributor**

3. Request role assignment from your administrator

## Network Connectivity Issues

### Cannot Reach Storage from VNet

**Symptoms**: Storage operations fail from VMs in the VNet

**Diagnostic Steps**:

1. **Verify Private Endpoint exists**:
   ```bash
   az network private-endpoint list \
     --resource-group rg-azure-networking-demo \
     --output table
   ```

2. **Check DNS resolution**:
   ```bash
   # From a VM in the VNet
   nslookup stsecureappXXXX.blob.core.windows.net
   
   # Should return a private IP (10.0.0.x), not public IP
   ```

3. **Verify Private DNS Zone**:
   ```bash
   az network private-dns zone list \
     --resource-group rg-azure-networking-demo
   
   az network private-dns record-set list \
     --resource-group rg-azure-networking-demo \
     --zone-name privatelink.blob.core.windows.net
   ```

4. **Check VNet link**:
   ```bash
   az network private-dns link vnet list \
     --resource-group rg-azure-networking-demo \
     --zone-name privatelink.blob.core.windows.net
   ```

**Common Solutions**:

| Issue | Solution |
|-------|----------|
| DNS returns public IP | Verify private DNS zone VNet link |
| Connection timeout | Check NSG rules on database subnet |
| Access denied | Verify storage network rules |

### NSG Blocking Traffic

**Symptoms**: Web traffic not reaching resources

**Diagnostic Steps**:

1. **View NSG rules**:
   ```bash
   az network nsg rule list \
     --resource-group rg-azure-networking-demo \
     --nsg-name nsg-snet-web \
     --output table
   ```

2. **Check effective rules on NIC**:
   ```bash
   az network nic list-effective-nsg \
     --resource-group rg-azure-networking-demo \
     --name <nic-name>
   ```

3. **Enable NSG flow logs** for detailed analysis

**Common Solutions**:

| Issue | Solution |
|-------|----------|
| Rule not applied | Check priority (lower = higher precedence) |
| Wrong direction | Verify Inbound vs Outbound |
| Source/Dest mismatch | Use Service Tags correctly |

### VNet Peering Issues

**Symptoms**: Cannot communicate between peered VNets

**Solution**:
```bash
# Check peering status
az network vnet peering list \
  --resource-group rg-azure-networking-demo \
  --vnet-name vnet-secure-app

# Verify peering is Connected (not Initiated)
```

## Storage Access Issues

### SAS Token Invalid or Expired

**Error**: `Server failed to authenticate the request`

**Diagnostic Steps**:

1. **Check token expiration**:
   - Decode SAS token and check `se` (expiry) parameter
   - Time is in UTC

2. **Verify permissions**:
   - Check `sp` parameter for required permissions
   - `r` = read, `w` = write, `d` = delete, `l` = list

3. **Regenerate token**:
   ```bash
   # Generate new SAS token
   az storage account generate-sas \
     --account-name $STORAGE_ACCOUNT \
     --account-key $ACCOUNT_KEY \
     --expiry $(date -u -d "+1 day" '+%Y-%m-%dT%H:%MZ') \
     --permissions rwdlacup \
     --resource-types sco \
     --services b \
     --output tsv
   ```

### Public Access Denied

**Error**: `Public access is not permitted on this storage account`

**Cause**: Public network access is disabled (by design)

**Solution**:
- Use private endpoint from VNet
- Or temporarily enable public access for testing:
  ```bash
  az storage account update \
    --name $STORAGE_ACCOUNT \
    --resource-group rg-azure-networking-demo \
    --public-network-access Enabled
  ```

### Container Not Found

**Error**: `The specified container does not exist`

**Solution**:
```bash
# List existing containers
az storage container list \
  --account-name $STORAGE_ACCOUNT \
  --sas-token "$SAS_TOKEN" \
  --output table

# Create container if missing
az storage container create \
  --account-name $STORAGE_ACCOUNT \
  --name mycontainer \
  --sas-token "$SAS_TOKEN"
```

### Blob Upload Fails

**Error**: `This request is not authorized to perform this operation`

**Diagnostic Steps**:

1. **Verify SAS permissions include write**:
   ```bash
   # Decode the sp parameter in your SAS token
   # Should include 'w' for write
   ```

2. **Check network rules**:
   ```bash
   az storage account show \
     --name $STORAGE_ACCOUNT \
     --query networkRuleSet
   ```

3. **Verify you're using correct endpoint**:
   - For private endpoint: DNS must resolve to private IP
   - Check: `nslookup $STORAGE_ACCOUNT.blob.core.windows.net`

## ARM Template Issues

### Template Validation Fails

**Error**: `Template validation failed`

**Solution**:

1. **Check JSON syntax**:
   ```bash
   # Validate JSON
   cat templates/complete-deployment.json | jq .
   ```

2. **Validate template**:
   ```bash
   az deployment group validate \
     --resource-group rg-azure-networking-demo \
     --template-file templates/complete-deployment.json \
     --parameters storageAccountName=test12345
   ```

3. **Common syntax errors**:
   - Missing commas between properties
   - Trailing commas (not allowed in JSON)
   - Mismatched brackets/braces

### Resource Not Found During Deployment

**Error**: `Resource X referenced by resource Y was not found`

**Cause**: Missing or incorrect `dependsOn`

**Solution**:
```json
{
  "type": "Microsoft.Network/privateEndpoints",
  "dependsOn": [
    "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName'))]",
    "[resourceId('Microsoft.Network/virtualNetworks', parameters('vnetName'))]"
  ]
}
```

### API Version Errors

**Error**: `The resource type could not be found in the namespace`

**Solution**:
```bash
# Find valid API versions
az provider show \
  --namespace Microsoft.Storage \
  --query "resourceTypes[?resourceType=='storageAccounts'].apiVersions" \
  --output table
```

### What-If Deployment Issues

**Error**: `What-If operation failed`

**Solution**:
```bash
# Run what-if with debug output
az deployment group what-if \
  --resource-group rg-azure-networking-demo \
  --template-file templates/complete-deployment.json \
  --parameters storageAccountName=test12345 \
  --debug
```

## Azure CLI Issues

### Not Logged In

**Error**: `Please run 'az login' to setup account`

**Solution**:
```bash
# Interactive login
az login

# For service principal
az login --service-principal \
  --username $APP_ID \
  --password $PASSWORD \
  --tenant $TENANT_ID

# For managed identity
az login --identity
```

### Wrong Subscription

**Error**: `Resource group 'X' could not be found`

**Solution**:
```bash
# List subscriptions
az account list --output table

# Set correct subscription
az account set --subscription "Your-Subscription-Name"

# Verify
az account show
```

### CLI Command Not Found

**Error**: `'az' is not recognized as a command`

**Solution**:
- Windows: Reinstall Azure CLI or add to PATH
- macOS: `brew install azure-cli`
- Linux: Follow [installation guide](https://docs.microsoft.com/cli/azure/install-azure-cli)

### Output Format Issues

**Solution**:
```bash
# Change default output format
az configure --defaults output=table

# Or specify per-command
az storage account list --output json
az storage account list --output table
az storage account list --output tsv
```

## Azure Portal Tips

### Finding Resources Quickly

1. **Use Global Search** (top bar): Type resource name
2. **Use Resource Groups**: Filter by resource group
3. **Use Tags**: Filter by tag values
4. **Recent Resources**: Check left sidebar

### Viewing Deployment History

1. Navigate to **Resource Group**
2. Click **Deployments** in left menu
3. Select deployment to view details
4. Click **Inputs** and **Outputs** tabs

### Exporting Templates

1. Navigate to resource or resource group
2. Click **Export template** in left menu
3. Download or copy template

### Diagnosing NSG Issues

1. Navigate to **Network Security Group**
2. Click **Effective security rules**
3. Select the NIC to analyze
4. View merged rules from all associated NSGs

### Monitoring Storage

1. Navigate to **Storage Account**
2. Click **Insights** for overview
3. Click **Metrics** for detailed charts
4. Click **Diagnostic settings** to enable logging

## Quick Reference

### Useful Commands

```bash
# Check Azure CLI version
az version

# Clear Azure CLI cache
az cache purge

# Get current user info
az ad signed-in-user show

# List all resources in group
az resource list --resource-group rg-azure-networking-demo --output table

# Get resource details
az resource show --ids <resource-id>

# Delete resource group (cleanup)
az group delete --name rg-azure-networking-demo --yes --no-wait
```

### Log Locations

| Log Type | Location |
|----------|----------|
| Azure CLI logs | `~/.azure/logs/` |
| Deployment logs | Azure Portal > Resource Group > Deployments |
| NSG flow logs | Storage account (if configured) |
| Storage logs | Storage account > Diagnostic settings |

## Getting Help

1. **Azure Documentation**: [docs.microsoft.com/azure](https://docs.microsoft.com/azure)
2. **Azure CLI Reference**: [docs.microsoft.com/cli/azure](https://docs.microsoft.com/cli/azure)
3. **Stack Overflow**: Tag `azure`, `azure-storage`, `azure-virtual-network`
4. **Azure Support**: For production issues, open support ticket

## Related Documentation

- [Virtual Network Setup](docs/01-virtual-network-setup.md)
- [Network Security Groups](docs/02-network-security-groups.md)
- [Storage Account Configuration](docs/03-storage-account-configuration.md)
- [Testing and Validation](docs/05-testing-and-validation.md)
