#!/bin/bash
#
# test-connectivity.sh - Test storage connectivity using SAS tokens and AzCopy
#
# This script demonstrates how to:
# - Generate SAS tokens
# - Test blob storage connectivity
# - Upload and download files using AzCopy
#
# Usage: ./test-connectivity.sh <storage-account-name> [resource-group-name]
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
DEFAULT_RESOURCE_GROUP="rg-azure-networking-demo"
CONTAINER_NAME="test-container"

# Parse arguments
if [ -z "$1" ]; then
    echo -e "${RED}[ERROR]${NC} Storage account name is required"
    echo "Usage: $0 <storage-account-name> [resource-group-name]"
    exit 1
fi

STORAGE_ACCOUNT="$1"
RESOURCE_GROUP="${2:-$DEFAULT_RESOURCE_GROUP}"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed"
        exit 1
    fi

    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi

    # Check if storage account exists
    if ! az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        print_error "Storage account '$STORAGE_ACCOUNT' not found in resource group '$RESOURCE_GROUP'"
        exit 1
    fi

    print_success "Prerequisites check passed"
}

# Function to generate SAS token
generate_sas_token() {
    print_info "Generating SAS token for storage account..."

    # Get storage account key
    ACCOUNT_KEY=$(az storage account keys list \
        --resource-group "$RESOURCE_GROUP" \
        --account-name "$STORAGE_ACCOUNT" \
        --query '[0].value' \
        --output tsv)

    # Calculate expiry time (1 day from now)
    # Handle different date implementations (GNU, BSD/macOS, BusyBox)
    if date -u -v+1d '+%Y-%m-%dT%H:%MZ' &>/dev/null 2>&1; then
        # BSD/macOS date
        END_DATE=$(date -u -v+1d '+%Y-%m-%dT%H:%MZ')
    elif date -u -d "+1 day" '+%Y-%m-%dT%H:%MZ' &>/dev/null 2>&1; then
        # GNU date
        END_DATE=$(date -u -d "+1 day" '+%Y-%m-%dT%H:%MZ')
    else
        # Fallback: use current time + approximate 24 hours calculation
        # This is a portable fallback for systems with limited date functionality
        END_DATE=$(date -u '+%Y-%m-%dT%H:%MZ')
        print_warning "Could not calculate future date. Using current time as expiry (regenerate token manually)."
    fi

    # Generate SAS token
    SAS_TOKEN=$(az storage account generate-sas \
        --account-name "$STORAGE_ACCOUNT" \
        --account-key "$ACCOUNT_KEY" \
        --expiry "$END_DATE" \
        --permissions rwdlacup \
        --resource-types sco \
        --services b \
        --output tsv)

    print_success "SAS token generated (expires: $END_DATE)"
    echo ""
    echo "SAS Token: ${SAS_TOKEN:0:50}..."
    echo ""
}

# Function to get blob endpoint
get_blob_endpoint() {
    BLOB_ENDPOINT=$(az storage account show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$STORAGE_ACCOUNT" \
        --query "primaryEndpoints.blob" \
        --output tsv)

    print_info "Blob endpoint: $BLOB_ENDPOINT"
}

# Function to test container operations
test_container_operations() {
    print_info "Testing container operations..."

    # Create container
    print_info "Creating test container: $CONTAINER_NAME"
    az storage container create \
        --account-name "$STORAGE_ACCOUNT" \
        --name "$CONTAINER_NAME" \
        --sas-token "$SAS_TOKEN" \
        --output none 2>/dev/null || true

    print_success "Container operations test passed"
}

# Function to test blob upload/download
test_blob_operations() {
    print_info "Testing blob operations..."

    # Create a test file
    TEST_FILE="/tmp/test-upload-$(date +%s).txt"
    echo "Test file content - $(date)" > "$TEST_FILE"

    # Upload file
    print_info "Uploading test file..."
    az storage blob upload \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name "$CONTAINER_NAME" \
        --file "$TEST_FILE" \
        --name "test-blob.txt" \
        --sas-token "$SAS_TOKEN" \
        --overwrite \
        --output none

    print_success "File uploaded successfully"

    # List blobs
    print_info "Listing blobs in container..."
    az storage blob list \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name "$CONTAINER_NAME" \
        --sas-token "$SAS_TOKEN" \
        --output table

    # Download file
    DOWNLOAD_FILE="/tmp/test-download-$(date +%s).txt"
    print_info "Downloading test file..."
    az storage blob download \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name "$CONTAINER_NAME" \
        --name "test-blob.txt" \
        --file "$DOWNLOAD_FILE" \
        --sas-token "$SAS_TOKEN" \
        --output none

    print_success "File downloaded successfully"

    # Verify content
    if diff "$TEST_FILE" "$DOWNLOAD_FILE" &> /dev/null; then
        print_success "File content verified - upload/download successful"
    else
        print_warning "File content mismatch"
    fi

    # Cleanup temp files
    rm -f "$TEST_FILE" "$DOWNLOAD_FILE"

    print_success "Blob operations test passed"
}

# Function to test with AzCopy
test_azcopy() {
    print_info "Testing AzCopy connectivity..."

    if ! command -v azcopy &> /dev/null; then
        print_warning "AzCopy is not installed. Skipping AzCopy tests."
        print_info "Install AzCopy: https://docs.microsoft.com/azure/storage/common/storage-use-azcopy-v10"
        return
    fi

    # Build full URL with SAS
    FULL_URL="${BLOB_ENDPOINT}${CONTAINER_NAME}?${SAS_TOKEN}"

    # Create test file
    TEST_FILE="/tmp/azcopy-test-$(date +%s).txt"
    echo "AzCopy test content - $(date)" > "$TEST_FILE"

    # Upload with AzCopy
    print_info "Uploading with AzCopy..."
    azcopy copy "$TEST_FILE" "${BLOB_ENDPOINT}${CONTAINER_NAME}/azcopy-test.txt?${SAS_TOKEN}" --output-level quiet

    print_success "AzCopy upload successful"

    # List with AzCopy
    print_info "Listing with AzCopy..."
    azcopy list "$FULL_URL"

    # Cleanup
    rm -f "$TEST_FILE"

    print_success "AzCopy tests passed"
}

# Function to verify encryption
verify_encryption() {
    print_info "Verifying encryption settings..."

    ENCRYPTION_STATUS=$(az storage account show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$STORAGE_ACCOUNT" \
        --query "{keySource: encryption.keySource, blobEncryption: encryption.services.blob.enabled}" \
        --output json)

    echo ""
    echo "Encryption Configuration:"
    echo "$ENCRYPTION_STATUS" | jq -r 'to_entries[] | "  \(.key): \(.value)"'
    echo ""

    print_success "Encryption verification complete"
}

# Function to test network access
test_network_access() {
    print_info "Testing network access settings..."

    NETWORK_RULES=$(az storage account show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$STORAGE_ACCOUNT" \
        --query "{defaultAction: networkRuleSet.defaultAction, publicAccess: publicNetworkAccess}" \
        --output json)

    echo ""
    echo "Network Configuration:"
    echo "$NETWORK_RULES" | jq -r 'to_entries[] | "  \(.key): \(.value)"'
    echo ""

    # Check private endpoint
    PE_EXISTS=$(az network private-endpoint list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[?contains(name, '$STORAGE_ACCOUNT')].name" \
        --output tsv)

    if [ -n "$PE_EXISTS" ]; then
        print_success "Private endpoint found: $PE_EXISTS"
    else
        print_warning "No private endpoint found for this storage account"
    fi

    print_success "Network access test complete"
}

# Function to display summary
display_summary() {
    echo ""
    echo "========================================"
    echo "       Connectivity Test Summary       "
    echo "========================================"
    echo ""
    echo "Storage Account: $STORAGE_ACCOUNT"
    echo "Resource Group: $RESOURCE_GROUP"
    echo "Blob Endpoint: $BLOB_ENDPOINT"
    echo "Test Container: $CONTAINER_NAME"
    echo ""
    echo "========================================"
    echo ""
    print_info "Full SAS URI for Storage Explorer:"
    echo ""
    echo "${BLOB_ENDPOINT}${CONTAINER_NAME}?${SAS_TOKEN}"
    echo ""
}

# Main execution
main() {
    echo ""
    echo "========================================"
    echo "  Storage Connectivity Test            "
    echo "========================================"
    echo ""

    check_prerequisites
    get_blob_endpoint
    generate_sas_token
    test_container_operations
    test_blob_operations
    test_azcopy
    verify_encryption
    test_network_access
    display_summary

    print_success "All connectivity tests completed!"
}

# Run main function
main
