#!/bin/bash
#
# cleanup.sh - Clean up all Azure resources created by this project
#
# This script removes the resource group and all resources within it.
#
# Usage: ./cleanup.sh [resource-group-name]
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

# Parse arguments
RESOURCE_GROUP="${1:-$DEFAULT_RESOURCE_GROUP}"

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

    print_success "Prerequisites check passed"
}

# Function to list resources
list_resources() {
    print_info "Resources in resource group '$RESOURCE_GROUP':"
    echo ""

    if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        print_warning "Resource group '$RESOURCE_GROUP' does not exist"
        exit 0
    fi

    az resource list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[].{Name:name, Type:type, Location:location}" \
        --output table

    echo ""
}

# Function to confirm deletion
confirm_deletion() {
    echo -e "${YELLOW}WARNING: This will permanently delete all resources in '$RESOURCE_GROUP'${NC}"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        print_info "Cleanup cancelled"
        exit 0
    fi
}

# Function to delete resource group
delete_resource_group() {
    print_info "Deleting resource group '$RESOURCE_GROUP'..."
    print_info "This may take several minutes..."

    az group delete \
        --name "$RESOURCE_GROUP" \
        --yes \
        --no-wait

    print_success "Resource group deletion initiated"
    print_info "The deletion is running in the background."
    print_info "You can check the status with: az group show --name $RESOURCE_GROUP"
}

# Function to wait for deletion
wait_for_deletion() {
    read -p "Do you want to wait for the deletion to complete? (yes/no): " WAIT_CONFIRM

    if [ "$WAIT_CONFIRM" != "yes" ]; then
        print_info "Cleanup initiated. Resources will be deleted in the background."
        return
    fi

    print_info "Waiting for deletion to complete..."

    while az group show --name "$RESOURCE_GROUP" &> /dev/null; do
        echo -n "."
        sleep 10
    done

    echo ""
    print_success "Resource group '$RESOURCE_GROUP' has been deleted"
}

# Main execution
main() {
    echo ""
    echo "========================================"
    echo "  Azure Resource Cleanup               "
    echo "========================================"
    echo ""

    check_prerequisites
    list_resources
    confirm_deletion
    delete_resource_group
    wait_for_deletion

    echo ""
    echo "========================================"
    echo "       Cleanup Complete!               "
    echo "========================================"
    echo ""
}

# Run main function
main
