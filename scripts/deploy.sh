#!/bin/bash
#
# deploy.sh - Deploy Azure Networking and Storage resources
#
# This script deploys the complete infrastructure including:
# - Virtual Network with Web and Database subnets
# - Network Security Group with HTTPS rule
# - Storage Account with private endpoint
# - Private DNS Zone for blob storage
#
# Usage: ./deploy.sh [resource-group-name] [location]
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
DEFAULT_LOCATION="eastus"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${SCRIPT_DIR}/../templates"

# Parse arguments
RESOURCE_GROUP="${1:-$DEFAULT_RESOURCE_GROUP}"
LOCATION="${2:-$DEFAULT_LOCATION}"

# Generate unique storage account name
RANDOM_SUFFIX=$(date +%s | tail -c 5)
STORAGE_ACCOUNT_NAME="stsecureapp${RANDOM_SUFFIX}"

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

# Function to check if Azure CLI is installed
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        print_info "Visit: https://docs.microsoft.com/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Check if logged in
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to create resource group
create_resource_group() {
    print_info "Creating resource group: ${RESOURCE_GROUP} in ${LOCATION}..."
    
    if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        print_warning "Resource group ${RESOURCE_GROUP} already exists"
    else
        az group create \
            --name "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --tags Environment=Demo Project=AzureNetworkingStorage \
            --output none
        print_success "Resource group created"
    fi
}

# Function to validate template
validate_template() {
    print_info "Validating deployment template..."
    
    az deployment group validate \
        --resource-group "$RESOURCE_GROUP" \
        --template-file "${TEMPLATE_DIR}/complete-deployment.json" \
        --parameters storageAccountName="$STORAGE_ACCOUNT_NAME" \
        --output none
    
    print_success "Template validation passed"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_info "Deploying infrastructure (this may take a few minutes)..."
    
    DEPLOYMENT_NAME="deployment-$(date +%Y%m%d-%H%M%S)"
    
    az deployment group create \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --template-file "${TEMPLATE_DIR}/complete-deployment.json" \
        --parameters storageAccountName="$STORAGE_ACCOUNT_NAME" \
        --output none
    
    print_success "Infrastructure deployed successfully"
}

# Function to display deployment outputs
display_outputs() {
    print_info "Retrieving deployment outputs..."
    
    echo ""
    echo "========================================"
    echo "       Deployment Complete!            "
    echo "========================================"
    echo ""
    
    echo "Resource Group: ${RESOURCE_GROUP}"
    echo "Location: ${LOCATION}"
    echo ""
    
    # Get VNet info
    VNET_NAME=$(az network vnet list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[0].name" \
        --output tsv)
    echo "Virtual Network: ${VNET_NAME}"
    
    # List subnets
    echo "Subnets:"
    az network vnet subnet list \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$VNET_NAME" \
        --query "[].{Name:name, AddressPrefix:addressPrefix}" \
        --output table
    
    echo ""
    
    # Get storage account info
    echo "Storage Account: ${STORAGE_ACCOUNT_NAME}"
    
    BLOB_ENDPOINT=$(az storage account show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$STORAGE_ACCOUNT_NAME" \
        --query "primaryEndpoints.blob" \
        --output tsv)
    echo "Blob Endpoint: ${BLOB_ENDPOINT}"
    
    # Get private endpoint info
    PE_NAME=$(az network private-endpoint list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[0].name" \
        --output tsv)
    
    if [ -n "$PE_NAME" ]; then
        PE_IP=$(az network private-endpoint show \
            --resource-group "$RESOURCE_GROUP" \
            --name "$PE_NAME" \
            --query "customDnsConfigs[0].ipAddresses[0]" \
            --output tsv)
        echo "Private Endpoint: ${PE_NAME} (${PE_IP})"
    fi
    
    echo ""
    echo "========================================"
    echo ""
    print_info "To clean up resources, run: ./cleanup.sh ${RESOURCE_GROUP}"
}

# Main execution
main() {
    echo ""
    echo "========================================"
    echo "  Azure Networking & Storage Deployment"
    echo "========================================"
    echo ""
    
    check_prerequisites
    create_resource_group
    validate_template
    deploy_infrastructure
    display_outputs
    
    print_success "Deployment completed successfully!"
}

# Run main function
main
