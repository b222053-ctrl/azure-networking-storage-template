<#
.SYNOPSIS
    Deploy Azure Networking and Storage resources.

.DESCRIPTION
    This script deploys the complete infrastructure including:
    - Virtual Network with Web and Database subnets
    - Network Security Group with HTTPS rule
    - Storage Account with private endpoint
    - Private DNS Zone for blob storage

.PARAMETER ResourceGroupName
    Name of the resource group to deploy to. Default: rg-azure-networking-demo

.PARAMETER Location
    Azure region for deployment. Default: eastus

.PARAMETER StorageAccountName
    Name of the storage account. If not provided, a unique name will be generated.

.EXAMPLE
    .\deploy.ps1

.EXAMPLE
    .\deploy.ps1 -ResourceGroupName "my-rg" -Location "westus2"

.EXAMPLE
    .\deploy.ps1 -StorageAccountName "mystorageaccount123"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ResourceGroupName = "rg-azure-networking-demo",

    [Parameter()]
    [string]$Location = "eastus",

    [Parameter()]
    [string]$StorageAccountName
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplateDir = Join-Path $ScriptDir "..\templates"

# Generate unique storage account name if not provided
if (-not $StorageAccountName) {
    $RandomSuffix = Get-Random -Maximum 99999
    $StorageAccountName = "stsecureapp$RandomSuffix"
}

# Function to write colored output
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."

    # Check if Az module is installed
    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        Write-Error "Azure PowerShell module is not installed."
        Write-Info "Run: Install-Module -Name Az -AllowClobber -Scope CurrentUser"
        throw "Azure PowerShell module required"
    }

    # Check if logged in
    try {
        $context = Get-AzContext
        if (-not $context) {
            throw "Not logged in"
        }
        Write-Info "Logged in as: $($context.Account.Id)"
        Write-Info "Subscription: $($context.Subscription.Name)"
    }
    catch {
        Write-Error "Not logged in to Azure. Please run 'Connect-AzAccount' first."
        throw
    }

    Write-Success "Prerequisites check passed"
}

# Function to create resource group
function New-ResourceGroupIfNotExists {
    Write-Info "Creating resource group: $ResourceGroupName in $Location..."

    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue

    if ($rg) {
        Write-Warning "Resource group $ResourceGroupName already exists"
    }
    else {
        New-AzResourceGroup `
            -Name $ResourceGroupName `
            -Location $Location `
            -Tag @{Environment = "Demo"; Project = "AzureNetworkingStorage" } `
            | Out-Null
        Write-Success "Resource group created"
    }
}

# Function to validate template
function Test-Template {
    Write-Info "Validating deployment template..."

    $templateFile = Join-Path $TemplateDir "complete-deployment.json"

    Test-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $templateFile `
        -storageAccountName $StorageAccountName `
        | Out-Null

    Write-Success "Template validation passed"
}

# Function to deploy infrastructure
function Deploy-Infrastructure {
    Write-Info "Deploying infrastructure (this may take a few minutes)..."

    $templateFile = Join-Path $TemplateDir "complete-deployment.json"
    $deploymentName = "deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

    $deployment = New-AzResourceGroupDeployment `
        -Name $deploymentName `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $templateFile `
        -storageAccountName $StorageAccountName `
        -Verbose

    if ($deployment.ProvisioningState -eq "Succeeded") {
        Write-Success "Infrastructure deployed successfully"
        return $deployment
    }
    else {
        throw "Deployment failed with state: $($deployment.ProvisioningState)"
    }
}

# Function to display deployment outputs
function Show-DeploymentOutputs {
    param($Deployment)

    Write-Host ""
    Write-Host "========================================"
    Write-Host "       Deployment Complete!            "
    Write-Host "========================================"
    Write-Host ""

    Write-Host "Resource Group: $ResourceGroupName"
    Write-Host "Location: $Location"
    Write-Host ""

    # Get VNet info
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName | Select-Object -First 1
    Write-Host "Virtual Network: $($vnet.Name)"

    Write-Host "Subnets:"
    foreach ($subnet in $vnet.Subnets) {
        Write-Host "  - $($subnet.Name): $($subnet.AddressPrefix)"
    }
    Write-Host ""

    # Get storage account info
    $storage = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    Write-Host "Storage Account: $($storage.StorageAccountName)"
    Write-Host "Blob Endpoint: $($storage.PrimaryEndpoints.Blob)"

    # Get private endpoint info
    $pe = Get-AzPrivateEndpoint -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pe) {
        $peIp = ($pe.CustomDnsConfigs | Select-Object -First 1).IpAddresses[0]
        Write-Host "Private Endpoint: $($pe.Name) ($peIp)"
    }

    Write-Host ""
    Write-Host "========================================"
    Write-Host ""

    # Display outputs from deployment
    if ($Deployment.Outputs) {
        Write-Info "Deployment Outputs:"
        $Deployment.Outputs.Keys | ForEach-Object {
            Write-Host "  $_: $($Deployment.Outputs[$_].Value)"
        }
    }

    Write-Host ""
    Write-Info "To clean up resources, run: .\cleanup.ps1 -ResourceGroupName $ResourceGroupName"
}

# Main execution
function Main {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  Azure Networking & Storage Deployment"
    Write-Host "========================================"
    Write-Host ""

    Test-Prerequisites
    New-ResourceGroupIfNotExists
    Test-Template
    $deployment = Deploy-Infrastructure
    Show-DeploymentOutputs -Deployment $deployment

    Write-Success "Deployment completed successfully!"
}

# Run main function
Main
