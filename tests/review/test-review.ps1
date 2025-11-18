#!/usr/bin/env pwsh
# PowerShell test suite for /sp.review command

$ErrorActionPreference = 'Continue'

# Test counters
$script:TestsRun = 0
$script:TestsPassed = 0
$script:TestsFailed = 0

# Get script paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$ReviewScript = Join-Path $RepoRoot "scripts/powershell/review-implementation.ps1"

# Test helper functions
function Print-TestHeader {
    param([string]$Message)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
}

function Assert-Equals {
    param(
        [string]$Expected,
        [string]$Actual,
        [string]$Message = "Assertion failed"
    )

    if ($Expected -eq $Actual) {
        return $true
    } else {
        Write-Host "✗ $Message" -ForegroundColor Red
        Write-Host "  Expected: $Expected" -ForegroundColor Gray
        Write-Host "  Actual:   $Actual" -ForegroundColor Gray
        return $false
    }
}

function Assert-FileExists {
    param(
        [string]$FilePath,
        [string]$Message = "File should exist: $FilePath"
    )

    if (Test-Path $FilePath -PathType Leaf) {
        return $true
    } else {
        Write-Host "✗ $Message" -ForegroundColor Red
        return $false
    }
}

function Assert-Contains {
    param(
        [string]$Haystack,
        [string]$Needle,
        [string]$Message = "String should contain substring"
    )

    if ($Haystack -like "*$Needle*") {
        return $true
    } else {
        Write-Host "✗ $Message" -ForegroundColor Red
        Write-Host "  Expected to contain: $Needle" -ForegroundColor Gray
        Write-Host "  In: $Haystack" -ForegroundColor Gray
        return $false
    }
}

function Run-Test {
    param(
        [string]$TestName,
        [scriptblock]$TestBlock
    )

    $script:TestsRun++

    Write-Host ""
    Write-Host "Running: $TestName" -ForegroundColor Yellow

    try {
        $result = & $TestBlock
        if ($result) {
            $script:TestsPassed++
            Write-Host "✓ PASSED: $TestName" -ForegroundColor Green
            return $true
        } else {
            $script:TestsFailed++
            Write-Host "✗ FAILED: $TestName" -ForegroundColor Red
            return $false
        }
    } catch {
        $script:TestsFailed++
        Write-Host "✗ FAILED: $TestName" -ForegroundColor Red
        Write-Host "  Exception: $_" -ForegroundColor Red
        return $false
    }
}

# Setup test environment
function Setup-TestEnv {
    $testDir = Join-Path $env:TEMP "speckit-test-$(Get-Random)"
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    Push-Location $testDir

    # Initialize git repo
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Create basic structure
    New-Item -ItemType Directory -Path "specs" -Force | Out-Null
    New-Item -ItemType Directory -Path "history" -Force | Out-Null
    New-Item -ItemType Directory -Path ".specify/templates" -Force | Out-Null

    # Create constitution
    @"
# Project Constitution

## Code Quality Standards
- All code must have tests
- All functions must have documentation
- Follow style guide
"@ | Out-File -FilePath "history/constitution.md" -Encoding UTF8

    git add .
    git commit -q -m "Initial commit"

    return $testDir
}

function Cleanup-TestEnv {
    param([string]$TestDir)

    if ($TestDir -and (Test-Path $TestDir)) {
        Pop-Location
        Remove-Item -Path $TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# =============================================================================
# Unit Tests - Script Validation
# =============================================================================

function Test-ReviewScriptExists {
    Assert-FileExists $ReviewScript "Review script should exist"
}

function Test-ReviewHelpOutput {
    $output = & $ReviewScript -Help 2>&1 | Out-String

    (Assert-Contains $output "Review implementation" "Help should show description") -and
    (Assert-Contains $output "Json" "Help should mention JSON option") -and
    (Assert-Contains $output "Mode" "Help should mention Mode option")
}

# =============================================================================
# Integration Tests - Mode Detection
# =============================================================================

function Test-ReviewModeQuick {
    $testDir = Setup-TestEnv

    git checkout -b 001-test-feature -q
    New-Item -ItemType Directory -Path "specs/001-test-feature" -Force | Out-Null
    "# Test Spec" | Out-File -FilePath "specs/001-test-feature/spec.md"
    "# Test Plan" | Out-File -FilePath "specs/001-test-feature/plan.md"

    $output = & $ReviewScript -Mode quick 2>&1 | Out-String

    Cleanup-TestEnv $testDir

    Assert-Contains $output "Mode: quick" "Should run in quick mode"
}

function Test-ReviewModeThorough {
    $testDir = Setup-TestEnv

    git checkout -b 001-test-feature -q
    New-Item -ItemType Directory -Path "specs/001-test-feature" -Force | Out-Null
    "# Test Spec" | Out-File -FilePath "specs/001-test-feature/spec.md"
    "# Test Plan" | Out-File -FilePath "specs/001-test-feature/plan.md"

    $output = & $ReviewScript -Mode thorough 2>&1 | Out-String

    Cleanup-TestEnv $testDir

    Assert-Contains $output "Mode: thorough" "Should run in thorough mode"
}

function Test-ReviewModeSecurity {
    $testDir = Setup-TestEnv

    git checkout -b 001-test-feature -q
    New-Item -ItemType Directory -Path "specs/001-test-feature" -Force | Out-Null
    "# Test Spec" | Out-File -FilePath "specs/001-test-feature/spec.md"
    "# Test Plan" | Out-File -FilePath "specs/001-test-feature/plan.md"

    $output = & $ReviewScript -Mode security 2>&1 | Out-String

    Cleanup-TestEnv $testDir

    Assert-Contains $output "Mode: security" "Should run in security mode"
}

function Test-ReviewModePerformance {
    $testDir = Setup-TestEnv

    git checkout -b 001-test-feature -q
    New-Item -ItemType Directory -Path "specs/001-test-feature" -Force | Out-Null
    "# Test Spec" | Out-File -FilePath "specs/001-test-feature/spec.md"
    "# Test Plan" | Out-File -FilePath "specs/001-test-feature/plan.md"

    $output = & $ReviewScript -Mode performance 2>&1 | Out-String

    Cleanup-TestEnv $testDir

    Assert-Contains $output "Mode: performance" "Should run in performance mode"
}

# =============================================================================
# Integration Tests - File Creation
# =============================================================================

function Test-ReviewCreatesContextFile {
    $testDir = Setup-TestEnv

    git checkout -b 001-test-feature -q
    New-Item -ItemType Directory -Path "specs/001-test-feature" -Force | Out-Null
    "# Test Spec" | Out-File -FilePath "specs/001-test-feature/spec.md"
    "# Test Plan" | Out-File -FilePath "specs/001-test-feature/plan.md"

    & $ReviewScript -Mode quick 2>&1 | Out-Null

    $contextFiles = Get-ChildItem -Path "specs/001-test-feature/reviews" -Filter "*_context.md" -ErrorAction SilentlyContinue

    Cleanup-TestEnv $testDir

    if ($contextFiles) {
        return $true
    } else {
        Write-Host "✗ Should create context file" -ForegroundColor Red
        return $false
    }
}

function Test-ReviewCreatesReviewFile {
    $testDir = Setup-TestEnv

    git checkout -b 001-test-feature -q
    New-Item -ItemType Directory -Path "specs/001-test-feature" -Force | Out-Null
    "# Test Spec" | Out-File -FilePath "specs/001-test-feature/spec.md"
    "# Test Plan" | Out-File -FilePath "specs/001-test-feature/plan.md"

    & $ReviewScript -Mode quick 2>&1 | Out-Null

    $reviewFiles = Get-ChildItem -Path "specs/001-test-feature/reviews" -Filter "*_review.md" -ErrorAction SilentlyContinue

    Cleanup-TestEnv $testDir

    if ($reviewFiles) {
        return $true
    } else {
        Write-Host "✗ Should create review file" -ForegroundColor Red
        return $false
    }
}

function Test-ReviewContextIncludesSpec {
    $testDir = Setup-TestEnv

    git checkout -b 001-test-feature -q
    New-Item -ItemType Directory -Path "specs/001-test-feature" -Force | Out-Null
    "# Test Specification" | Out-File -FilePath "specs/001-test-feature/spec.md"
    "# Test Plan" | Out-File -FilePath "specs/001-test-feature/plan.md"

    & $ReviewScript -Mode quick 2>&1 | Out-Null

    $contextFile = Get-ChildItem -Path "specs/001-test-feature/reviews" -Filter "*_context.md" -ErrorAction SilentlyContinue | Select-Object -First 1
    $content = ""
    if ($contextFile) {
        $content = Get-Content $contextFile.FullName -Raw
    }

    Cleanup-TestEnv $testDir

    (Assert-Contains $content "Feature Specification" "Context should include spec section") -and
    (Assert-Contains $content "Test Specification" "Context should include spec content")
}

function Test-ReviewContextIncludesPlan {
    $testDir = Setup-TestEnv

    git checkout -b 001-test-feature -q
    New-Item -ItemType Directory -Path "specs/001-test-feature" -Force | Out-Null
    "# Test Spec" | Out-File -FilePath "specs/001-test-feature/spec.md"
    "# Implementation Plan Details" | Out-File -FilePath "specs/001-test-feature/plan.md"

    & $ReviewScript -Mode quick 2>&1 | Out-Null

    $contextFile = Get-ChildItem -Path "specs/001-test-feature/reviews" -Filter "*_context.md" -ErrorAction SilentlyContinue | Select-Object -First 1
    $content = ""
    if ($contextFile) {
        $content = Get-Content $contextFile.FullName -Raw
    }

    Cleanup-TestEnv $testDir

    (Assert-Contains $content "Implementation Plan" "Context should include plan section") -and
    (Assert-Contains $content "Implementation Plan Details" "Context should include plan content")
}

# =============================================================================
# Integration Tests - JSON Output
# =============================================================================

function Test-ReviewJsonOutput {
    $testDir = Setup-TestEnv

    git checkout -b 001-test-feature -q
    New-Item -ItemType Directory -Path "specs/001-test-feature" -Force | Out-Null
    "# Test Spec" | Out-File -FilePath "specs/001-test-feature/spec.md"
    "# Test Plan" | Out-File -FilePath "specs/001-test-feature/plan.md"

    $output = & $ReviewScript -Mode quick -Json 2>&1 | Out-String

    Cleanup-TestEnv $testDir

    try {
        $json = $output | ConvertFrom-Json
        ($null -ne $json.review_id) -and ($null -ne $json.context_file) -and ($null -ne $json.review_file)
    } catch {
        Write-Host "✗ Output should be valid JSON" -ForegroundColor Red
        return $false
    }
}

# =============================================================================
# Error Handling Tests
# =============================================================================

function Test-ReviewErrorNoSpec {
    $testDir = Setup-TestEnv

    git checkout -b 001-test-feature -q
    New-Item -ItemType Directory -Path "specs/001-test-feature" -Force | Out-Null
    "# Test Plan" | Out-File -FilePath "specs/001-test-feature/plan.md"

    $output = & $ReviewScript -Mode quick 2>&1 | Out-String
    $LASTEXITCODE_saved = $LASTEXITCODE

    Cleanup-TestEnv $testDir

    if ($LASTEXITCODE_saved -ne 0) {
        Assert-Contains $output "Spec not found" "Should error when spec missing"
    } else {
        Write-Host "✗ Should fail when spec is missing" -ForegroundColor Red
        return $false
    }
}

function Test-ReviewErrorNoPlan {
    $testDir = Setup-TestEnv

    git checkout -b 001-test-feature -q
    New-Item -ItemType Directory -Path "specs/001-test-feature" -Force | Out-Null
    "# Test Spec" | Out-File -FilePath "specs/001-test-feature/spec.md"

    $output = & $ReviewScript -Mode quick 2>&1 | Out-String
    $LASTEXITCODE_saved = $LASTEXITCODE

    Cleanup-TestEnv $testDir

    if ($LASTEXITCODE_saved -ne 0) {
        Assert-Contains $output "Plan not found" "Should error when plan missing"
    } else {
        Write-Host "✗ Should fail when plan is missing" -ForegroundColor Red
        return $false
    }
}

# =============================================================================
# Run All Tests
# =============================================================================

function Main {
    Print-TestHeader "SpecKit Plus Review Command Test Suite (PowerShell)"

    Write-Host "Repository: $RepoRoot"
    Write-Host "Review Script: $ReviewScript"

    # Unit Tests - Script Validation
    Print-TestHeader "Unit Tests - Script Validation"
    Run-Test "Review script exists" { Test-ReviewScriptExists }
    Run-Test "Review script shows help" { Test-ReviewHelpOutput }

    # Integration Tests - Mode Detection
    Print-TestHeader "Integration Tests - Mode Detection"
    Run-Test "Review mode: quick" { Test-ReviewModeQuick }
    Run-Test "Review mode: thorough" { Test-ReviewModeThorough }
    Run-Test "Review mode: security" { Test-ReviewModeSecurity }
    Run-Test "Review mode: performance" { Test-ReviewModePerformance }

    # Integration Tests - File Creation
    Print-TestHeader "Integration Tests - File Creation"
    Run-Test "Review creates context file" { Test-ReviewCreatesContextFile }
    Run-Test "Review creates review file" { Test-ReviewCreatesReviewFile }
    Run-Test "Context includes spec" { Test-ReviewContextIncludesSpec }
    Run-Test "Context includes plan" { Test-ReviewContextIncludesPlan }

    # Integration Tests - JSON Output
    Print-TestHeader "Integration Tests - JSON Output"
    Run-Test "Review JSON output" { Test-ReviewJsonOutput }

    # Error Handling Tests
    Print-TestHeader "Error Handling Tests"
    Run-Test "Review errors when spec missing" { Test-ReviewErrorNoSpec }
    Run-Test "Review errors when plan missing" { Test-ReviewErrorNoPlan }

    # Summary
    Print-TestHeader "Test Summary"
    Write-Host ""
    Write-Host "Tests Run:    $script:TestsRun"
    Write-Host "Tests Passed: $script:TestsPassed" -ForegroundColor Green
    Write-Host "Tests Failed: $script:TestsFailed" -ForegroundColor Red
    Write-Host ""

    if ($script:TestsFailed -eq 0) {
        Write-Host "✓ All tests passed!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "✗ Some tests failed" -ForegroundColor Red
        exit 1
    }
}

# Run main function
Main
