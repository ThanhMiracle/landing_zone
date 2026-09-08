# Validates all Terraform stacks.
# Works on Windows by running terraform directly from real stack paths.
# Requirements: R4.1-R4.8, R2.7, R12.1

param(
    [string]$InfraRoot = (Join-Path $PSScriptRoot "..")
)

$InfraRoot = Resolve-Path $InfraRoot

$BACKEND_TF = @'
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
'@

# Provider configs per stack - only alias provider (no required_providers to avoid conflict)
# Stacks with configuration_aliases already declare required_providers in main.tf
$providerConfigs = @{
    "management-groups" = @'
provider "azurerm" {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}
'@
    "platform/connectivity" = @'
provider "azurerm" {
  alias           = "connectivity"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}
'@
    "platform/management" = @'
provider "azurerm" {
  alias           = "management"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}
'@
    "platform/identity" = @'
provider "azurerm" {
  alias           = "identity"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}
'@
    "platform/security" = @'
provider "azurerm" {
  alias           = "security"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}
'@
    "application/baseline" = @'
provider "azurerm" {
  alias           = "workload"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}
provider "azurerm" {
  alias           = "connectivity"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}
'@
    "application/workloads/aks" = @'
provider "azurerm" {
  alias           = "workload"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}
'@
    "application/workloads/postgresql" = @'
provider "azurerm" {
  alias           = "workload"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}
'@
    "application/workloads/redis" = @'
provider "azurerm" {
  alias           = "workload"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}
'@
    "application/workloads/service-bus" = @'
provider "azurerm" {
  alias           = "workload"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}
'@
    "application/workloads/vm-bastion" = @'
provider "azurerm" {
  alias           = "workload"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}
'@
    # governance/rbac uses a default (non-aliased) provider
    "governance/rbac" = @'
provider "azurerm" {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}
'@
}

# Stacks that already have terraform { required_providers } in main.tf
# For these, we only generate provider instance (NOT terraform block)
$hasOwnRequiredProviders = @(
    "application/workloads/redis",
    "application/workloads/service-bus",
    "governance/rbac"
)

# Stacks that need a full terraform + required_providers block
$TERRAFORM_BLOCK = @'
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
'@

$stacks = @(
    "management-groups",
    "platform/connectivity",
    "platform/management",
    "platform/identity",
    "platform/security",
    "application/baseline",
    "application/workloads/aks",
    "application/workloads/postgresql",
    "application/workloads/redis",
    "application/workloads/service-bus",
    "application/workloads/vm-bastion",
    "governance/rbac"
)

$passed = 0
$failed = 0

Write-Host ""
Write-Host "=== Terraform Validate - All Stacks ===" -ForegroundColor Cyan
Write-Host "InfraRoot: $InfraRoot"
Write-Host ""

foreach ($s in $stacks) {
    $stackPath = Join-Path $InfraRoot "stacks\$s"
    
    if (-not (Test-Path $stackPath)) {
        Write-Host "[SKIP]   $s - directory not found" -ForegroundColor Yellow
        continue
    }
    
    $backendFile = Join-Path $stackPath "backend.tf"
    $providerFile = Join-Path $stackPath "provider_generated.tf"
    $dotTerraform = Join-Path $stackPath ".terraform"
    $tfstate = Join-Path $stackPath "terraform.tfstate"
    $tflock = Join-Path $stackPath ".terraform.lock.hcl"
    
    try {
        # Generate backend.tf
        $BACKEND_TF | Set-Content $backendFile -Encoding utf8
        
        # Generate provider_generated.tf
        $providerContent = $providerConfigs[$s]
        if ($hasOwnRequiredProviders -contains $s) {
            # Only generate provider instance, not required_providers block
            $providerContent | Set-Content $providerFile -Encoding utf8
        } else {
            # Generate full terraform block + provider
            ($TERRAFORM_BLOCK + "`n" + $providerContent) | Set-Content $providerFile -Encoding utf8
        }
        
        if (Test-Path $dotTerraform) { Remove-Item $dotTerraform -Recurse -Force }
        
        Push-Location $stackPath
        
        $initOut = & terraform init -no-color -reconfigure 2>&1
        $initExit = $LASTEXITCODE
        
        if ($initExit -ne 0) {
            Write-Host "[FAIL]   $s - terraform init failed" -ForegroundColor Red
            $initOut | Where-Object { $_ -match "Error" } | Select-Object -First 5 | ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
            $failed++
            Pop-Location
            continue
        }
        
        $validateOut = & terraform validate -no-color 2>&1
        $validateExit = $LASTEXITCODE
        
        if ($validateExit -eq 0) {
            Write-Host "[PASS]   $s" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "[FAIL]   $s - terraform validate failed" -ForegroundColor Red
            $validateOut | Where-Object { $_ -match "Error|error" } | Select-Object -First 5 | ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
            $failed++
        }
        
        Pop-Location
    } catch {
        Write-Host "[ERROR]  $s - $($_.Exception.Message)" -ForegroundColor Red
        $failed++
        try { Pop-Location } catch {}
    } finally {
        if (Test-Path $backendFile) { Remove-Item $backendFile -Force -ErrorAction SilentlyContinue }
        if (Test-Path $providerFile) { Remove-Item $providerFile -Force -ErrorAction SilentlyContinue }
        if (Test-Path $dotTerraform) { Remove-Item $dotTerraform -Recurse -Force -ErrorAction SilentlyContinue }
        if (Test-Path $tfstate) { Remove-Item $tfstate -Force -ErrorAction SilentlyContinue }
        if (Test-Path $tflock) { Remove-Item $tflock -Force -ErrorAction SilentlyContinue }
    }
}

Write-Host ""
Write-Host "Passed: $passed / $($passed + $failed)" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

if ($failed -gt 0) {
    Write-Host "VALIDATION FAILED" -ForegroundColor Red
    exit 1
} else {
    Write-Host "All stacks validated successfully!" -ForegroundColor Green
    exit 0
}
