# 05 - Testing and Validation

## Overview

This guide covers testing storage access using SAS tokens, Azure Storage Explorer, and AzCopy, plus verifying encryption and network connectivity.

## Table of Contents

- [SAS Token Generation](#sas-token-generation)
- [Azure Storage Explorer](#azure-storage-explorer)
- [AzCopy Testing](#azcopy-testing)
- [Encryption Verification](#encryption-verification)
- [Network Connectivity Testing](#network-connectivity-testing)

## SAS Token Generation

### What is a SAS Token?

A Shared Access Signature (SAS) token provides secure delegated access to resources in your storage account without exposing account keys.

### Types of SAS

| Type | Scope | Use Case |
|------|-------|----------|
| **Account SAS** | Entire storage account | Admin operations |
| **Service SAS** | Single service (Blob, File, etc.) | Limited access |
| **User Delegation SAS** | Azure AD credentials | Most secure option |

### Generate Account SAS Token

#### Azure Portal

1. Navigate to your **Storage Account**
2. Click **Shared access signature** in the left menu
3. Configure permissions:
   - **Allowed services**: Blob
   - **Allowed resource types**: Container, Object
   - **Allowed permissions**: Read, Write, List, Create
   - **Start and expiry date/time**: Set appropriate values
4. Click **Generate SAS and connection string**
5. Copy the **SAS token** (starts with `?sv=...`)

#### Azure CLI

```bash
# Set variables
STORAGE_ACCOUNT="stsecureappXXXX"
RESOURCE_GROUP="rg-azure-networking-demo"

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --query '[0].value' \
  --output tsv)

# Generate SAS token (valid for 1 day)
END_DATE=$(date -u -d "+1 day" '+%Y-%m-%dT%H:%MZ')

SAS_TOKEN=$(az storage account generate-sas \
  --account-name $STORAGE_ACCOUNT \
  --account-key $ACCOUNT_KEY \
  --expiry $END_DATE \
  --permissions rwdlacup \
  --resource-types sco \
  --services b \
  --output tsv)

echo "SAS Token: $SAS_TOKEN"
```

#### PowerShell

```powershell
$storageAccount = "stsecureappXXXX"
$resourceGroup = "rg-azure-networking-demo"

# Get storage context
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -AccountName $storageAccount)[0].Value
$context = New-AzStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey

# Generate SAS token
$sasToken = New-AzStorageAccountSASToken `
  -Context $context `
  -Service Blob `
  -ResourceType Container,Object `
  -Permission rwdlacup `
  -ExpiryTime (Get-Date).AddDays(1)

Write-Host "SAS Token: $sasToken"
```

### SAS Token Security

> ⚠️ **Security Best Practices:**
> - Use shortest possible expiry time
> - Apply minimum necessary permissions
> - Use User Delegation SAS when possible
> - Rotate and revoke tokens regularly
> - Never commit SAS tokens to source control

## Azure Storage Explorer

### Installation

#### Windows

1. Download from [Azure Storage Explorer](https://azure.microsoft.com/features/storage-explorer/)
2. Run the installer
3. Follow the setup wizard

#### macOS

```bash
# Using Homebrew
brew install --cask microsoft-azure-storage-explorer
```

#### Linux

```bash
# Ubuntu/Debian
sudo snap install storage-explorer
```

### Connecting Using SAS URI

#### Step 1: Get the SAS URI

```bash
# Construct full SAS URI
BLOB_ENDPOINT=$(az storage account show \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --query primaryEndpoints.blob \
  --output tsv)

SAS_URI="${BLOB_ENDPOINT}?${SAS_TOKEN}"
echo "SAS URI: $SAS_URI"
```

#### Step 2: Connect in Storage Explorer

1. Open Azure Storage Explorer
2. Click **Connect** icon (plug icon)
3. Select **Blob container or directory**
4. Choose **Shared access signature URL (SAS)**
5. Paste the SAS URI
6. Click **Next** → **Connect**

### Creating Containers and Uploading Files

#### Using Storage Explorer

1. **Create Container**:
   - Right-click your storage account
   - Select **Create Blob Container**
   - Enter name: `test-container`
   - Press Enter

2. **Upload Files**:
   - Select the container
   - Click **Upload** → **Upload Files**
   - Select files from your computer
   - Click **Upload**

3. **Download Files**:
   - Select files in the container
   - Click **Download**
   - Choose destination folder

#### Using Azure CLI

```bash
# Create container
az storage container create \
  --account-name $STORAGE_ACCOUNT \
  --name test-container \
  --sas-token "$SAS_TOKEN"

# Upload file
az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --container-name test-container \
  --file /path/to/local/file.txt \
  --name uploaded-file.txt \
  --sas-token "$SAS_TOKEN"

# List blobs
az storage blob list \
  --account-name $STORAGE_ACCOUNT \
  --container-name test-container \
  --sas-token "$SAS_TOKEN" \
  --output table
```

## AzCopy Testing

### Installation

#### Windows

```powershell
# Download and extract
Invoke-WebRequest -Uri "https://aka.ms/downloadazcopy-v10-windows" -OutFile azcopy.zip
Expand-Archive azcopy.zip -DestinationPath .
# Add to PATH or use full path
```

#### macOS

```bash
# Using Homebrew
brew install azcopy
```

#### Linux

```bash
# Download
wget https://aka.ms/downloadazcopy-v10-linux -O azcopy.tar.gz

# Extract
tar -xzf azcopy.tar.gz

# Move to PATH
sudo mv azcopy_linux_amd64_*/azcopy /usr/local/bin/
```

### Verify Installation

```bash
azcopy --version
```

### Basic Commands

#### Upload a File

```bash
# Single file upload
azcopy copy "/path/to/local/file.txt" \
  "https://${STORAGE_ACCOUNT}.blob.core.windows.net/test-container/file.txt?${SAS_TOKEN}"
```

#### Upload a Directory

```bash
# Recursive directory upload
azcopy copy "/path/to/local/folder" \
  "https://${STORAGE_ACCOUNT}.blob.core.windows.net/test-container?${SAS_TOKEN}" \
  --recursive=true
```

#### Download a File

```bash
# Single file download
azcopy copy \
  "https://${STORAGE_ACCOUNT}.blob.core.windows.net/test-container/file.txt?${SAS_TOKEN}" \
  "/path/to/local/file.txt"
```

#### Download a Directory

```bash
# Recursive directory download
azcopy copy \
  "https://${STORAGE_ACCOUNT}.blob.core.windows.net/test-container?${SAS_TOKEN}" \
  "/path/to/local/folder" \
  --recursive=true
```

#### Sync Directories

```bash
# Sync local to blob (upload changes only)
azcopy sync "/path/to/local/folder" \
  "https://${STORAGE_ACCOUNT}.blob.core.windows.net/test-container?${SAS_TOKEN}" \
  --recursive=true
```

#### List Blobs

```bash
# List container contents
azcopy list \
  "https://${STORAGE_ACCOUNT}.blob.core.windows.net/test-container?${SAS_TOKEN}"
```

### Example Scenarios

#### Scenario 1: Backup Local Directory

```bash
#!/bin/bash
# backup-to-azure.sh

STORAGE_ACCOUNT="stsecureappXXXX"
CONTAINER="backups"
SOURCE="/home/user/data"
SAS_TOKEN="?sv=2021-06-08&ss=b&srt=sco..."

# Create timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Upload with timestamp folder
azcopy copy "$SOURCE" \
  "https://${STORAGE_ACCOUNT}.blob.core.windows.net/${CONTAINER}/${TIMESTAMP}?${SAS_TOKEN}" \
  --recursive=true

echo "Backup completed to $TIMESTAMP"
```

#### Scenario 2: Download Latest Backup

```bash
#!/bin/bash
# restore-from-azure.sh

STORAGE_ACCOUNT="stsecureappXXXX"
CONTAINER="backups"
DESTINATION="/home/user/restore"
SAS_TOKEN="?sv=2021-06-08&ss=b&srt=sco..."
BACKUP_FOLDER="20240101-120000"

azcopy copy \
  "https://${STORAGE_ACCOUNT}.blob.core.windows.net/${CONTAINER}/${BACKUP_FOLDER}?${SAS_TOKEN}" \
  "$DESTINATION" \
  --recursive=true

echo "Restore completed from $BACKUP_FOLDER"
```

### AzCopy Performance Tips

```bash
# Increase concurrency (default: 300)
export AZCOPY_CONCURRENCY_VALUE=500

# Enable automatic decompression
azcopy copy "source" "destination" --decompress

# Show transfer statistics
azcopy jobs show <job-id>

# Resume failed transfer
azcopy jobs resume <job-id>
```

## Encryption Verification

### Verify Server-Side Encryption

#### Azure CLI

```bash
# Check storage account encryption settings
az storage account show \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --query '{
    keySource: encryption.keySource,
    blobEncryption: encryption.services.blob.enabled,
    fileEncryption: encryption.services.file.enabled,
    queueEncryption: encryption.services.queue.enabled,
    tableEncryption: encryption.services.table.enabled
  }'
```

Expected output:
```json
{
  "keySource": "Microsoft.Storage",
  "blobEncryption": true,
  "fileEncryption": true,
  "queueEncryption": true,
  "tableEncryption": true
}
```

#### Azure Portal

1. Navigate to **Storage Account**
2. Click **Encryption** in the left menu
3. Verify:
   - Encryption type: Microsoft-managed keys
   - All services encrypted

### Verify Blob Encryption Status

```bash
# Check specific blob's encryption
az storage blob show \
  --account-name $STORAGE_ACCOUNT \
  --container-name test-container \
  --name uploaded-file.txt \
  --sas-token "$SAS_TOKEN" \
  --query properties.serverEncrypted
```

Should return: `true`

### Verify HTTPS Enforcement

```bash
# Check HTTPS-only setting
az storage account show \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --query enableHttpsTrafficOnly
```

Should return: `true`

### Verify TLS Version

```bash
# Check minimum TLS version
az storage account show \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --query minimumTlsVersion
```

Should return: `TLS1_2`

## Network Connectivity Testing

### Test from Local Machine (Public Access)

If public access is disabled, this should fail:

```bash
# This should fail if public access is disabled
curl -I "https://${STORAGE_ACCOUNT}.blob.core.windows.net/"
```

Expected: Connection refused or timeout

### Test from VM in VNet

Deploy a test VM in the database subnet and run:

```bash
# Test DNS resolution (should return private IP)
nslookup ${STORAGE_ACCOUNT}.blob.core.windows.net

# Test connectivity
curl -I "https://${STORAGE_ACCOUNT}.blob.core.windows.net/"

# Test blob access
az storage blob list \
  --account-name $STORAGE_ACCOUNT \
  --container-name test-container \
  --auth-mode login
```

### Verify Private Endpoint

```bash
# Get private endpoint IP
az network private-endpoint show \
  --resource-group $RESOURCE_GROUP \
  --name pe-storage-blob \
  --query 'customDnsConfigs[0].ipAddresses[0]' \
  --output tsv
```

### DNS Resolution Test

From a VM in the VNet:

```bash
# Should resolve to private IP (e.g., 10.0.0.4)
nslookup ${STORAGE_ACCOUNT}.blob.core.windows.net

# Using dig
dig +short ${STORAGE_ACCOUNT}.blob.core.windows.net
```

### Network Rule Verification

```bash
# Check network rules
az storage account show \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --query '{
    defaultAction: networkRuleSet.defaultAction,
    virtualNetworkRules: networkRuleSet.virtualNetworkRules,
    publicNetworkAccess: publicNetworkAccess
  }'
```

Expected output (if properly secured):
```json
{
  "defaultAction": "Deny",
  "virtualNetworkRules": [...],
  "publicNetworkAccess": "Disabled"
}
```

## Testing Checklist

Use this checklist to verify your deployment:

### Storage Account
- [ ] Storage account created successfully
- [ ] Correct SKU (Standard_LRS)
- [ ] HTTPS-only enabled
- [ ] Minimum TLS version is 1.2
- [ ] Public blob access disabled

### Encryption
- [ ] Server-side encryption enabled
- [ ] Using Microsoft-managed keys
- [ ] All services encrypted

### Network Security
- [ ] Public network access disabled
- [ ] Private endpoint created
- [ ] Private DNS zone configured
- [ ] DNS resolves to private IP

### Connectivity
- [ ] Can connect from VNet via private endpoint
- [ ] Cannot connect from public internet
- [ ] SAS token works correctly

### Data Operations
- [ ] Can create containers
- [ ] Can upload blobs
- [ ] Can download blobs
- [ ] Can list blobs

## Common Issues and Solutions

| Issue | Possible Cause | Solution |
|-------|----------------|----------|
| SAS token invalid | Expired or incorrect permissions | Generate new token |
| Connection timeout | Public access disabled | Use private endpoint or allow network |
| DNS not resolving | Private DNS zone misconfigured | Verify zone and VNet link |
| Storage Explorer can't connect | Firewall blocking | Check network rules |
| AzCopy fails | Invalid SAS or URL | Verify full URI with token |
| Encryption not showing | Blob not yet uploaded | Upload a blob and re-check |

## Next Steps

After completing testing:

1. Review [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) for additional help
2. Clean up resources using [scripts/cleanup.sh](../scripts/cleanup.sh)
3. Explore [LEARNING-OBJECTIVES.md](../LEARNING-OBJECTIVES.md) for further study

## Additional Resources

- [SAS Token Documentation](https://docs.microsoft.com/azure/storage/common/storage-sas-overview)
- [Azure Storage Explorer](https://docs.microsoft.com/azure/vs-azure-tools-storage-manage-with-storage-explorer)
- [AzCopy Reference](https://docs.microsoft.com/azure/storage/common/storage-ref-azcopy)
- [Storage Network Security](https://docs.microsoft.com/azure/storage/common/storage-network-security)
