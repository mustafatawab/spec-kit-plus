#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Review implementation against spec, plan, and tasks

.DESCRIPTION
    This script gathers all context and prepares it for AI review:
    - Constitution (if exists)
    - Spec (requirements, success criteria)
    - Plan (technical design)
    - Tasks (implementation checklist)
    - Actual code implementation

.PARAMETER Json
    Output in JSON format

.PARAMETER Mode
    Review mode: quick|thorough|security|performance (default: quick)

.PARAMETER Agent
    Agent name for tracking (default: current user)

.PARAMETER IncludeDiff
    Include git diff in review context

.EXAMPLE
    .\review-implementation.ps1 -Mode quick

.EXAMPLE
    .\review-implementation.ps1 -Mode thorough -Agent gemini

.EXAMPLE
    .\review-implementation.ps1 -Mode security -IncludeDiff
#>

[CmdletBinding()]
param(
    [switch]$Json,
    [ValidateSet('quick', 'thorough', 'security', 'performance')]
    [string]$Mode = 'quick',
    [string]$Agent = $env:USERNAME,
    [switch]$IncludeDiff,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

# Source common functions
. "$PSScriptRoot/common.ps1"

# Get feature paths and validate branch
$paths = Get-FeaturePathsEnv

if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit:$paths.HAS_GIT)) {
    exit 1
}

# Check prerequisites
if (-not (Test-Path $paths.FEATURE_SPEC -PathType Leaf)) {
    Write-Error "Spec not found: $($paths.FEATURE_SPEC)"
    Write-Output "Run /sp.specify first to create the specification."
    exit 1
}

if (-not (Test-Path $paths.IMPL_PLAN -PathType Leaf)) {
    Write-Error "Plan not found: $($paths.IMPL_PLAN)"
    Write-Output "Run /sp.plan first to create the implementation plan."
    exit 1
}

# Check if tasks exist
$tasksExist = Test-Path $paths.TASKS -PathType Leaf

# Gather review context
$reviewDir = Join-Path $paths.FEATURE_DIR "reviews"
New-Item -ItemType Directory -Path $reviewDir -Force | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reviewId = "${timestamp}_${Mode}_${Agent}"
$contextFile = Join-Path $reviewDir "${reviewId}_context.md"

# Create review context document
$contextContent = @"
# Code Review Context: $($paths.CURRENT_BRANCH)

**Review ID:** $reviewId
**Mode:** $Mode
**Agent:** $Agent
**Timestamp:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')
**Branch:** $($paths.CURRENT_BRANCH)

---

## Review Objectives

"@

# Add mode-specific objectives
switch ($Mode) {
    'quick' {
        $contextContent += @"

### Quick Review Objectives
- Verify all spec requirements are implemented
- Check that success criteria are met
- Identify obvious bugs or issues
- Ensure basic quality standards
- Review time: 5-10 minutes

"@
    }
    'thorough' {
        $contextContent += @"

### Thorough Review Objectives
- Deep analysis of code quality
- Architecture alignment with plan
- Test coverage verification
- Error handling completeness
- Documentation quality
- Performance considerations
- Review time: 20-30 minutes

"@
    }
    'security' {
        $contextContent += @"

### Security Review Objectives
- Input validation and sanitization
- Authentication and authorization
- SQL injection prevention
- XSS vulnerability check
- CSRF protection
- Secrets management
- Dependency vulnerabilities
- Review time: 15-20 minutes

"@
    }
    'performance' {
        $contextContent += @"

### Performance Review Objectives
- Algorithm efficiency
- Database query optimization
- Caching opportunities
- Memory usage
- Network request optimization
- Bundle size (frontend)
- Review time: 15-20 minutes

"@
    }
}

# Add Constitution if exists
$constitutionFile = Join-Path $paths.REPO_ROOT "history/constitution.md"
if (Test-Path $constitutionFile -PathType Leaf) {
    $constitution = Get-Content $constitutionFile -Raw
    $contextContent += @"

## Constitution (Quality Guidelines)

``````markdown
$constitution
``````

---

"@
}

# Add Specification
$spec = Get-Content $paths.FEATURE_SPEC -Raw
$contextContent += @"

## Feature Specification

**File:** ``$($paths.FEATURE_SPEC)``

``````markdown
$spec
``````

---

"@

# Add Implementation Plan
$plan = Get-Content $paths.IMPL_PLAN -Raw
$contextContent += @"

## Implementation Plan

**File:** ``$($paths.IMPL_PLAN)``

``````markdown
$plan
``````

---

"@

# Add Tasks if exists
if ($tasksExist) {
    $tasks = Get-Content $paths.TASKS -Raw
    $contextContent += @"

## Implementation Tasks

**File:** ``$($paths.TASKS)``

``````markdown
$tasks
``````

---

"@
}

# Add Data Model if exists
$dataModelFile = Join-Path $paths.FEATURE_DIR "data-model.md"
if (Test-Path $dataModelFile -PathType Leaf) {
    $dataModel = Get-Content $dataModelFile -Raw
    $contextContent += @"

## Data Model

**File:** ``$dataModelFile``

``````markdown
$dataModel
``````

---

"@
}

# Add git diff if requested
if ($IncludeDiff -and $paths.HAS_GIT) {
    try {
        $diff = git diff main...HEAD 2>$null
        $contextContent += @"

## Code Changes (Git Diff)

**Compared to:** main branch

``````diff
$diff
``````

---

"@
    } catch {
        # Ignore diff errors
    }
}

# Add file tree
$files = Get-ChildItem -Recurse -File |
    Where-Object {
        $_.FullName -notmatch '[\\/]\.git[\\/]' -and
        $_.FullName -notmatch '[\\/]node_modules[\\/]' -and
        $_.FullName -notmatch '[\\/]dist[\\/]' -and
        $_.FullName -notmatch '[\\/]build[\\/]' -and
        $_.FullName -notmatch '[\\/]__pycache__[\\/]' -and
        $_.FullName -notmatch '[\\/]venv[\\/]'
    } |
    Select-Object -First 100 -ExpandProperty FullName

$fileTree = $files -join "`n"

$contextContent += @"

## Implementation Files

**Working Directory:** $(Get-Location)

``````
$fileTree
``````

---

## Review Checklist Template

Use this template to structure your review:

### 1. Spec Compliance
- [ ] All functional requirements implemented
- [ ] All acceptance criteria met
- [ ] Success criteria achievable
- [ ] Edge cases handled

### 2. Quality Assessment
- [ ] Code follows constitution guidelines
- [ ] Proper error handling
- [ ] Adequate test coverage
- [ ] Clear documentation
- [ ] Consistent code style

### 3. Architecture Alignment
- [ ] Follows implementation plan
- [ ] Data models match specification
- [ ] API contracts honored
- [ ] Dependencies properly managed

### 4. Issues Identified
List any issues found with:
- File path and line number
- Severity (critical, high, medium, low)
- Description of issue
- Suggested fix

### 5. Improvement Opportunities
List suggestions for:
- Code quality improvements
- Performance optimizations
- Better error handling
- Documentation enhancements

### 6. Overall Assessment
- **Status:** Ready for merge | Needs minor fixes | Needs major rework
- **Confidence:** High | Medium | Low
- **Recommendation:** Approve | Request changes | Reject

---

## Instructions for Reviewer

1. Read the specification carefully
2. Review the implementation plan and tasks
3. Examine the actual code implementation
4. Fill out the review checklist above
5. Provide specific, actionable feedback
6. Include file paths and line numbers for all issues
7. Suggest concrete improvements

**Remember:** The goal is to ensure implementation matches specification and follows quality guidelines.

"@

# Write context file
$contextContent | Out-File -FilePath $contextFile -Encoding UTF8

# Create review template
$reviewFile = Join-Path $reviewDir "${reviewId}_review.md"

$reviewTemplate = @"
# Code Review: $($paths.CURRENT_BRANCH)

**Review ID:** $reviewId
**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')
**Mode:** $Mode
**Reviewer:** $Agent

---

## Summary

<!-- Provide 2-3 sentence summary of your review findings -->

---

## Spec Compliance

<!-- Check each requirement from the spec -->

### Requirements Coverage
- [ ] Requirement 1: ...
- [ ] Requirement 2: ...

### Acceptance Criteria
- [ ] Criterion 1: ...
- [ ] Criterion 2: ...

### Success Criteria
- [ ] Can the defined success metrics be achieved with this implementation?

---

## Quality Assessment

<!-- Based on constitution and best practices -->

### Code Quality
- **Rating:** ⭐⭐⭐☆☆ (X/5)
- **Comments:** ...

### Test Coverage
- **Rating:** ⭐⭐⭐☆☆ (X/5)
- **Comments:** ...

### Documentation
- **Rating:** ⭐⭐⭐☆☆ (X/5)
- **Comments:** ...

---

## Issues Found

<!-- List all issues with severity and location -->

### Critical Issues (Must fix before merge)
1. **File:** ``path/to/file.ts:123``
   - **Issue:** Description
   - **Fix:** Suggested solution

### High Priority Issues
1. ...

### Medium Priority Issues
1. ...

### Low Priority Issues / Nitpicks
1. ...

---

## Improvement Opportunities

<!-- Suggestions that aren't blocking but would improve quality -->

1. **Performance:** ...
2. **Maintainability:** ...
3. **Security:** ...

---

## Architecture Alignment

- [ ] Follows implementation plan
- [ ] Matches data model
- [ ] Uses planned dependencies
- [ ] Adheres to design patterns

**Deviations from plan:**
- ...

---

## Overall Assessment

**Status:** 🟢 Ready for merge | 🟡 Needs minor fixes | 🔴 Needs major rework

**Confidence Level:** High | Medium | Low

**Recommendation:** ✅ Approve | 🔄 Request changes | ❌ Reject

**Next Steps:**
1. ...
2. ...

---

## Reviewer Notes

<!-- Any additional context or observations -->

"@

$reviewTemplate | Out-File -FilePath $reviewFile -Encoding UTF8

# Output results
if ($Json) {
    [PSCustomObject]@{
        review_id    = $reviewId
        mode         = $Mode
        context_file = $contextFile
        review_file  = $reviewFile
        spec_file    = $paths.FEATURE_SPEC
        plan_file    = $paths.IMPL_PLAN
        tasks_file   = $paths.TASKS
        tasks_exist  = $tasksExist
    } | ConvertTo-Json -Compress
} else {
    Write-Output "✅ Review context prepared"
    Write-Output ""
    Write-Output "Review ID: $reviewId"
    Write-Output "Mode: $Mode"
    Write-Output ""
    Write-Output "Context file: $contextFile"
    Write-Output "Review file: $reviewFile"
    Write-Output ""
    Write-Output "Next steps:"
    Write-Output "1. Read the context file to understand what needs review"
    Write-Output "2. Examine the code implementation"
    Write-Output "3. Fill out the review template with your findings"
    Write-Output "4. Save the completed review"
    Write-Output ""
    if ($Agent -ne $env:USERNAME) {
        Write-Output "Note: Review agent ($Agent) is different from current user"
        Write-Output "This provides a fresh perspective on the implementation."
    }
}
