<#
.SYNOPSIS
    Tái tạo Windows directory junction points cho tất cả environments sau khi clone repo.

.DESCRIPTION
    Git không track Windows junction points (symlinks). Script này tái tạo
    các junctions dưới infra/environments/ trỏ đến stacks/ tương ứng.
    
    Mỗi environment directory (dev, test, uat, pre-production, staging, prod)
    là một junction point trỏ đến infra/stacks/ — Terragrunt dùng
    find_in_parent_folders() để đọc env.hcl từ thư mục environment.

.PREREQUISITES
    - Windows OS
    - PowerShell 5.0 trở lên
    - Quyền Administrator (cần thiết để tạo junction points)
    - Git repo đã được clone về máy

.JUNCTIONS MANAGED
    infra/environments/dev/stacks            -> infra/stacks
    infra/environments/test/stacks           -> infra/stacks
    infra/environments/uat/stacks            -> infra/stacks
    infra/environments/pre-production/stacks -> infra/stacks
    infra/environments/staging/stacks        -> infra/stacks
    infra/environments/prod/stacks           -> infra/stacks

.EXAMPLE
    # Chạy từ thư mục gốc của repo:
    .\infra\scripts\setup-junctions.ps1

    # Hoặc chỉ định đường dẫn infra:
    .\infra\scripts\setup-junctions.ps1 -InfraRoot "C:\projects\myrepo\infra"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$InfraRoot = (Join-Path $PSScriptRoot "..")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Kiểm tra quyền Administrator
# ---------------------------------------------------------------------------
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error @"
ERROR: Script này yêu cầu quyền Administrator để tạo junction points.
Vui lòng mở PowerShell với quyền 'Run as Administrator' và chạy lại script.
"@
    exit 1
}

# ---------------------------------------------------------------------------
# Resolve đường dẫn tuyệt đối
# ---------------------------------------------------------------------------
$InfraRoot = Resolve-Path $InfraRoot
$StacksSource = Join-Path $InfraRoot "stacks"

if (-not (Test-Path $StacksSource)) {
    Write-Error "ERROR: Không tìm thấy thư mục stacks tại: $StacksSource"
    exit 1
}

# ---------------------------------------------------------------------------
# Danh sách junctions cần tạo
# Format: @{ Target = "<junction path>"; Source = "<actual path>" }
# ---------------------------------------------------------------------------
$environments = @("dev", "test", "uat", "pre-production", "staging", "prod")

$junctions = @()
foreach ($env in $environments) {
    $junctions += @{
        Target = Join-Path $InfraRoot "environments\$env\stacks"
        Source = $StacksSource
        Env    = $env
    }
}

# ---------------------------------------------------------------------------
# Xử lý từng junction
# ---------------------------------------------------------------------------
$totalProcessed = 0
$totalCreated   = 0
$totalExisting  = 0
$totalFailed    = 0

Write-Host ""
Write-Host "=== Setup Junction Points ===" -ForegroundColor Cyan
Write-Host "InfraRoot : $InfraRoot"
Write-Host "Source    : $StacksSource"
Write-Host ""

foreach ($j in $junctions) {
    $totalProcessed++
    $target = $j.Target
    $source = $j.Source
    $envName = $j.Env

    # Kiểm tra nếu junction đã tồn tại
    if (Test-Path $target) {
        $item = Get-Item $target -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            Write-Host "[SKIP]   $envName\stacks — junction đã tồn tại." -ForegroundColor Yellow
            $totalExisting++
            continue
        } else {
            Write-Warning "[WARN]   $envName\stacks — đường dẫn tồn tại nhưng không phải junction. Bỏ qua."
            $totalFailed++
            continue
        }
    }

    # Tạo thư mục cha nếu chưa tồn tại
    $parentDir = Split-Path $target -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # Tạo junction point
    try {
        $null = New-Item -ItemType Junction -Path $target -Value $source
        Write-Host "[CREATE] $envName\stacks -> $source" -ForegroundColor Green
        $totalCreated++
    } catch {
        Write-Host "[FAIL]   $envName\stacks — Lỗi: $_" -ForegroundColor Red
        $totalFailed++
    }
}

# ---------------------------------------------------------------------------
# In tóm tắt
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Kết Quả ===" -ForegroundColor Cyan
Write-Host "Tổng xử lý   : $totalProcessed"
Write-Host "Đã tạo mới   : $totalCreated" -ForegroundColor Green
Write-Host "Đã tồn tại   : $totalExisting" -ForegroundColor Yellow
Write-Host "Thất bại     : $totalFailed" -ForegroundColor $(if ($totalFailed -gt 0) { "Red" } else { "White" })
Write-Host ""

if ($totalFailed -gt 0) {
    Write-Warning "Một số junctions không được tạo. Kiểm tra log ở trên."
    exit 1
}

Write-Host "Hoàn thành! Chạy 'terragrunt run-all validate' từ bất kỳ thư mục environments/<env>/ để xác nhận." -ForegroundColor Green
