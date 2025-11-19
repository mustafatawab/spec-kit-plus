#!/usr/bin/env pwsh
# Common PowerShell functions analogous to common.sh

# Check if we're in a git worktree (not the main working tree)
function Test-IsWorktree {
    try {
        $gitDir = git rev-parse --git-dir 2>$null
        if ($LASTEXITCODE -ne 0) {
            return $false  # Not in a git repo
        }

        # In a worktree, .git is a file, not a directory
        # Or git-dir contains "worktrees"
        return ((Test-Path $gitDir -PathType Leaf) -or ($gitDir -like "*\worktrees\*") -or ($gitDir -like "*/worktrees/*"))
    } catch {
        return $false
    }
}

# Get the main repository root (not worktree directory)
# This is where specs/, history/, templates/ should be accessed from
function Get-GitCommonDir {
    try {
        $commonDir = git rev-parse --git-common-dir 2>$null
        if ($LASTEXITCODE -ne 0) {
            return $null
        }

        # Get the parent of .git directory
        return (Resolve-Path (Join-Path $commonDir "..")).Path
    } catch {
        return $null
    }
}

# Get repository root, with fallback for non-git repositories
# In worktree mode, this returns the MAIN repo root (where specs/ lives)
# Not the worktree directory
function Get-RepoRoot {
    try {
        $result = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0) {
            # Check if we're in a worktree
            if (Test-IsWorktree) {
                # Return main repo root, not worktree directory
                $commonDir = Get-GitCommonDir
                if ($commonDir) {
                    return $commonDir
                }
            }
            # Normal git repo
            return $result
        }
    } catch {
        # Git command failed
    }

    # Fall back to script location for non-git repos
    return (Resolve-Path (Join-Path $PSScriptRoot "../../..")).Path
}

# Get current worktree directory (where we're currently working)
function Get-WorktreeDir {
    try {
        $result = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
    } catch {
        # Git command failed
    }

    return (Get-Location).Path
}

function Get-CurrentBranch {
    # First check if SPECIFY_FEATURE environment variable is set
    if ($env:SPECIFY_FEATURE) {
        return $env:SPECIFY_FEATURE
    }
    
    # Then check git if available
    try {
        $result = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
    } catch {
        # Git command failed
    }
    
    # For non-git repos, try to find the latest feature directory
    $repoRoot = Get-RepoRoot
    $specsDir = Join-Path $repoRoot "specs"
    
    if (Test-Path $specsDir) {
        $latestFeature = ""
        $highest = 0
        
        Get-ChildItem -Path $specsDir -Directory | ForEach-Object {
            if ($_.Name -match '^(\d{3})-') {
                $num = [int]$matches[1]
                if ($num -gt $highest) {
                    $highest = $num
                    $latestFeature = $_.Name
                }
            }
        }
        
        if ($latestFeature) {
            return $latestFeature
        }
    }
    
    # Final fallback
    return "main"
}

function Test-HasGit {
    try {
        git rev-parse --show-toplevel 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Test-FeatureBranch {
    param(
        [string]$Branch,
        [bool]$HasGit = $true
    )
    
    # For non-git repos, we can't enforce branch naming but still provide output
    if (-not $HasGit) {
        Write-Warning "[specify] Warning: Git repository not detected; skipped branch validation"
        return $true
    }
    
    if ($Branch -notmatch '^[0-9]{3}-') {
        Write-Output "ERROR: Not on a feature branch. Current branch: $Branch"
        Write-Output "Feature branches should be named like: 001-feature-name"
        return $false
    }
    return $true
}

function Get-FeatureDir {
    param([string]$RepoRoot, [string]$Branch)
    Join-Path $RepoRoot "specs/$Branch"
}

function Get-FeaturePathsEnv {
    $repoRoot = Get-RepoRoot
    $currentBranch = Get-CurrentBranch
    $hasGit = Test-HasGit
    $featureDir = Get-FeatureDir -RepoRoot $repoRoot -Branch $currentBranch
    
    [PSCustomObject]@{
        REPO_ROOT     = $repoRoot
        CURRENT_BRANCH = $currentBranch
        HAS_GIT       = $hasGit
        FEATURE_DIR   = $featureDir
        FEATURE_SPEC  = Join-Path $featureDir 'spec.md'
        IMPL_PLAN     = Join-Path $featureDir 'plan.md'
        TASKS         = Join-Path $featureDir 'tasks.md'
        RESEARCH      = Join-Path $featureDir 'research.md'
        DATA_MODEL    = Join-Path $featureDir 'data-model.md'
        QUICKSTART    = Join-Path $featureDir 'quickstart.md'
        CONTRACTS_DIR = Join-Path $featureDir 'contracts'
    }
}

function Test-FileExists {
    param([string]$Path, [string]$Description)
    if (Test-Path -Path $Path -PathType Leaf) {
        Write-Output "  ✓ $Description"
        return $true
    } else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

function Test-DirHasFiles {
    param([string]$Path, [string]$Description)
    if ((Test-Path -Path $Path -PathType Container) -and (Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | Select-Object -First 1)) {
        Write-Output "  ✓ $Description"
        return $true
    } else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

# ============================================================================
# Git Worktree Functions
# ============================================================================

# List all git worktrees
function Get-Worktrees {
    if (-not (Test-HasGit)) {
        Write-Error "Not in a git repository"
        return
    }

    git worktree list
}

# Validate branch name according to git-check-ref-format rules
function Test-BranchName {
    param([string]$Name)

    # Check for spaces
    if ($Name -match '\s') {
        Write-Error "Branch name cannot contain spaces"
        $suggested = $Name -replace '\s', '-'
        Write-Host "Use hyphens instead: $suggested" -ForegroundColor Yellow
        return $false
    }

    # Check length
    if ($Name.Length -gt 200) {
        Write-Error "Branch name too long (max 200 characters)"
        Write-Host "Current length: $($Name.Length)" -ForegroundColor Yellow
        return $false
    }

    # Check invalid characters
    if ($Name -match '[\[\]^~:?*\\]' -or $Name -match '\.\.' -or $Name -match '^\.' -or $Name -match '\.$') {
        Write-Error "Branch name contains invalid characters"
        Write-Host "Avoid: spaces [ ] ^ ~ : ? * \ .. (leading/trailing dots)" -ForegroundColor Yellow
        return $false
    }

    return $true
}

# Create a new git worktree for a feature branch
# Usage: New-Worktree -BranchName "001-feature" [-WorktreePath "path"]
function New-Worktree {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BranchName,

        [Parameter(Mandatory=$false)]
        [string]$WorktreePath = ""
    )

    if (-not (Test-HasGit)) {
        Write-Error "Not in a git repository"
        Write-Host ""
        Write-Host "Worktrees require a git repository. Initialize one with:" -ForegroundColor Yellow
        Write-Host "  git init" -ForegroundColor Cyan
        return
    }

    if ([string]::IsNullOrWhiteSpace($BranchName)) {
        Write-Error "Branch name required"
        Write-Host ""
        Write-Host "Usage: New-Worktree -BranchName <branch-name> [-WorktreePath <path>]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Example:" -ForegroundColor Yellow
        Write-Host "  New-Worktree -BranchName '001-user-auth'" -ForegroundColor Cyan
        Write-Host "  New-Worktree -BranchName '002-dashboard' -WorktreePath '../my-worktrees/dashboard'" -ForegroundColor Cyan
        return
    }

    # Validate branch name
    if (-not (Test-BranchName -Name $BranchName)) {
        return
    }

    # Get repo root for default path
    $repoRoot = Get-RepoRoot

    # Default worktree path: ../worktrees/<branch-name>
    if ([string]::IsNullOrWhiteSpace($WorktreePath)) {
        $worktreesDir = Join-Path (Split-Path $repoRoot -Parent) "worktrees"
        New-Item -Path $worktreesDir -ItemType Directory -Force | Out-Null
        $WorktreePath = Join-Path $worktreesDir $BranchName
    }

    # Check if worktree path already exists
    if (Test-Path $WorktreePath) {
        Write-Error "Path already exists: $WorktreePath"
        if (Test-Path $WorktreePath -PathType Container) {
            Write-Host "Remove the directory first:" -ForegroundColor Yellow
            Write-Host "  Remove-Item -Recurse '$WorktreePath'" -ForegroundColor Cyan
            Write-Host "Or choose a different path" -ForegroundColor Yellow
        }
        return
    }

    # Check if branch already exists
    try {
        git rev-parse --verify $BranchName 2>$null | Out-Null
        $branchExists = ($LASTEXITCODE -eq 0)
    } catch {
        $branchExists = $false
    }

    if ($branchExists) {
        # Branch exists, create worktree from it
        Write-Host "Creating worktree for existing branch '$BranchName'..." -ForegroundColor Yellow
        git worktree add $WorktreePath $BranchName
    } else {
        # Create new branch and worktree
        Write-Host "Creating new branch '$BranchName' and worktree..." -ForegroundColor Yellow
        git worktree add -b $BranchName $WorktreePath
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Output $WorktreePath
        return $WorktreePath
    } else {
        return $null
    }
}

# Remove a git worktree
# Usage: Remove-Worktree -WorktreePath "path"
function Remove-Worktree {
    param(
        [Parameter(Mandatory=$true)]
        [string]$WorktreePath
    )

    if (-not (Test-HasGit)) {
        Write-Error "Not in a git repository"
        return
    }

    if ([string]::IsNullOrWhiteSpace($WorktreePath)) {
        Write-Error "Worktree path required"
        Write-Host ""
        Write-Host "Usage: Remove-Worktree -WorktreePath <path>" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To list existing worktrees:" -ForegroundColor Yellow
        Write-Host "  git worktree list" -ForegroundColor Cyan
        return
    }

    # Check if worktree has uncommitted changes
    if ((Test-Path $WorktreePath) -and (git -C $WorktreePath status --porcelain 2>$null | Where-Object { $_ })) {
        Write-Warning "Worktree has uncommitted changes:"
        git -C $WorktreePath status --short
        Write-Host ""
        $confirm = Read-Host "Continue with removal? (y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "Aborted." -ForegroundColor Yellow
            return
        }
    }

    git worktree remove $WorktreePath
}

# Prune stale worktree references
function Remove-StaleWorktrees {
    if (-not (Test-HasGit)) {
        Write-Error "Not in a git repository"
        return
    }

    git worktree prune
}

# Check if worktree mode is enabled
# Checks for SPECIFY_WORKTREE_MODE environment variable
function Test-WorktreeModeEnabled {
    return ($env:SPECIFY_WORKTREE_MODE -eq "true")
}

