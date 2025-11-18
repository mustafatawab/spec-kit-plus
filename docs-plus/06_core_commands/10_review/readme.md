# `/sp.review` - Implementation Review Command

## Overview

The `/sp.review` command provides AI-assisted code review of your implementation against the specification, plan, tasks, and quality guidelines (constitution). It gathers all context automatically and performs a structured review based on the mode you select.

## Purpose

- **Ensure spec compliance:** Verify all requirements are implemented
- **Quality assurance:** Check code follows constitution and best practices
- **Multi-agent review:** Run same code through different AI agents for fresh perspectives
- **Pre-PR validation:** Catch issues before creating pull requests
- **Continuous improvement:** Identify optimization opportunities

## Usage

```bash
/sp.review [mode] [options]
```

### Review Modes

#### Quick Review (default)
**Time:** 5-10 minutes
**Focus:** Spec compliance and obvious issues

```bash
/sp.review
# or
/sp.review quick
```

**Checks:**
- All spec requirements implemented?
- Success criteria met?
- Obvious bugs or issues?
- Basic error handling present?

#### Thorough Review
**Time:** 20-30 minutes
**Focus:** Deep quality analysis

```bash
/sp.review thorough
```

**Checks:**
- Code quality and architecture
- Test coverage verification
- Error handling completeness
- Documentation quality
- Performance considerations
- Design pattern adherence

#### Security Review
**Time:** 15-20 minutes
**Focus:** Vulnerability scanning

```bash
/sp.review security
```

**Checks:**
- Input validation and sanitization
- Authentication and authorization
- SQL injection prevention
- XSS vulnerability check
- CSRF protection
- Secrets management
- Dependency vulnerabilities

#### Performance Review
**Time:** 15-20 minutes
**Focus:** Optimization opportunities

```bash
/sp.review performance
```

**Checks:**
- Algorithm efficiency (Big O analysis)
- Database query optimization
- Caching opportunities
- Memory usage patterns
- Network request optimization
- Bundle size (for frontend)

### Additional Options

#### Include Git Diff
Add code changes to review context:

```bash
/sp.review --include-diff
```

#### Different Agent Review
Prepare review for a different AI agent:

```bash
/sp.review thorough --agent gemini
```

This creates the context file that you can copy to another AI agent for a fresh perspective.

## What Gets Reviewed

The review command automatically gathers:

1. **Constitution** (`history/constitution.md`) - Quality guidelines
2. **Specification** (`specs/{feature}/spec.md`) - Requirements and success criteria
3. **Implementation Plan** (`specs/{feature}/plan.md`) - Technical design
4. **Tasks** (`specs/{feature}/tasks.md`) - Implementation checklist
5. **Data Model** (`specs/{feature}/data-model.md`) - If exists
6. **Code Implementation** - Files in working directory
7. **Git Diff** - If `--include-diff` flag used

## Review Output

Reviews are saved in `specs/{feature}/reviews/` directory:

```
specs/001-user-auth/reviews/
├── 20241118_143022_quick_claude_context.md   # All context for review
└── 20241118_143022_quick_claude_review.md    # Completed review
```

### Review File Structure

Each review contains:

1. **Summary** - 2-3 sentence overview
2. **Spec Compliance** - Requirements coverage checklist
3. **Quality Assessment** - Ratings for code quality, tests, docs
4. **Issues Found** - Categorized by severity (critical, high, medium, low)
5. **Improvement Opportunities** - Non-blocking suggestions
6. **Architecture Alignment** - Plan compliance check
7. **Overall Assessment** - Ready/Needs fixes/Reject + next steps

## Example Workflow

### Pre-PR Review

```bash
# Implement feature
/sp.implement

# Quick review before PR
/sp.review

# Fix any critical issues found
# ... make fixes ...

# Thorough review for final validation
/sp.review thorough

# Create PR
/sp.git.commit_pr
```

### Multi-Agent Review

```bash
# Review with Claude
/sp.review thorough

# Get second opinion from Gemini
/sp.review thorough --agent gemini
# Copy context to Gemini, get their review

# Compare reviews and address all issues
```

### Security Audit

```bash
# Before deploying to production
/sp.review security --include-diff

# Address all critical and high priority security issues
```

## Review Quality Guidelines

### Issue Reporting
Issues should include:
- **File path and line number**: `src/auth/jwt.ts:45`
- **Severity**: Critical, High, Medium, Low
- **Description**: Clear explanation of the problem
- **Impact**: Why it matters
- **Suggested fix**: Specific solution

**Example:**
```markdown
### Critical Issues
1. **File:** `src/api/tasks.ts:45`
   - **Issue:** No input validation on task title - allows empty strings
   - **Impact:** Database constraint violations, poor UX
   - **Fix:** Add validation: `if (!title?.trim()) throw new Error('Title required')`
```

### Rating Scale
Quality ratings use 1-5 stars:
- ⭐☆☆☆☆ (1/5) - Major issues, needs rework
- ⭐⭐☆☆☆ (2/5) - Significant issues, considerable work needed
- ⭐⭐⭐☆☆ (3/5) - Acceptable, some improvements needed
- ⭐⭐⭐⭐☆ (4/5) - Good quality, minor issues only
- ⭐⭐⭐⭐⭐ (5/5) - Excellent, production-ready

## Integration with Workflow

The review command fits into the spec-driven development loop:

```
/sp.specify
    ↓
/sp.plan
    ↓
/sp.tasks
    ↓
/sp.implement
    ↓
/sp.review ← You are here
    ↓
(Fix issues)
    ↓
/sp.review (validate fixes)
    ↓
/sp.git.commit_pr
```

## Best Practices

### 1. Review Early and Often
Don't wait until feature is complete:
```bash
# After implementing core functionality
/sp.review quick

# After adding tests
/sp.review thorough

# Before final PR
/sp.review security
```

### 2. Use Different Modes
Each mode serves a different purpose:
- **Quick**: Daily development checks
- **Thorough**: Before PR submission
- **Security**: Before production deployment
- **Performance**: When optimizing critical paths

### 3. Track Review History
Keep all reviews for historical reference:
```bash
# Reviews accumulate in specs/{feature}/reviews/
# Shows quality improvement over time
```

### 4. Multi-Agent Validation
For critical features, get multiple perspectives:
```bash
/sp.review thorough              # Claude review
/sp.review thorough --agent gemini  # Gemini review
# Compare findings, address all issues
```

## Prerequisites

Before running `/sp.review`:

1. **Spec exists**: `specs/{feature}/spec.md`
2. **Plan exists**: `specs/{feature}/plan.md`
3. **On feature branch**: Not on main branch
4. **Code implemented**: Something to review

The command will error if spec or plan is missing.

## Review Script Details

### Bash
```bash
scripts/bash/review-implementation.sh --mode quick
```

### PowerShell
```powershell
scripts/powershell/review-implementation.ps1 -Mode quick
```

### Script Options
- `--json` / `-Json`: Output in JSON format
- `--mode <mode>` / `-Mode <mode>`: Review mode (quick/thorough/security/performance)
- `--agent <name>` / `-Agent <name>`: Agent name for tracking
- `--include-diff` / `-IncludeDiff`: Include git diff in context
- `--help` / `-Help`: Show help message

## Tips and Tricks

### 1. Review Before Every Commit
Make it a habit:
```bash
/sp.review quick && git commit -am "feat: Add feature"
```

### 2. Automate Reviews in CI/CD
Add to `.github/workflows/review.yml`:
```yaml
- name: Quick Review
  run: |
    bash scripts/bash/review-implementation.sh --mode quick
```

### 3. Share Reviews with Team
Review files are markdown - commit them:
```bash
git add specs/001-feature/reviews/
git commit -m "docs: Add code review for feature 001"
```

### 4. Compare Review Modes
Run multiple modes to get comprehensive coverage:
```bash
/sp.review quick
/sp.review security
/sp.review performance
# Address all findings
```

## Troubleshooting

### "Spec not found"
```bash
# Make sure you've created the spec first
/sp.specify "Your feature description"
```

### "Plan not found"
```bash
# Create the plan
/sp.plan
```

### "Not on feature branch"
```bash
# Create a feature branch first
git checkout -b 001-your-feature
# Or use worktree mode
/sp.worktree create "your feature"
```

### Review too generic
Use `--include-diff` for more specific feedback:
```bash
/sp.review thorough --include-diff
```

## Related Commands

- [`/sp.specify`](../03_spec/readme.md) - Create specification
- [`/sp.plan`](../04_plan/readme.md) - Design implementation
- [`/sp.implement`](../07_implementation/readme.md) - Execute TDD cycle
- [`/sp.git.commit_pr`](../09_git_commit_pr/readme.md) - Create PR

## Advanced Usage

### Custom Review Criteria
Add project-specific checks to constitution:
```bash
/sp.constitution

# Add to constitution:
## Code Review Standards
- All API endpoints must have rate limiting
- All database queries must use indexes
- All user inputs must be validated
```

Reviews will automatically check against these standards.

### Review Templates
Customize review templates in `.specify/templates/review-template.md`

### Review Metrics
Track review quality over time:
```bash
# Count issues per review
grep -r "Critical Issues" specs/*/reviews/

# Track quality ratings
grep -r "Rating:" specs/*/reviews/
```

## Summary

The `/sp.review` command provides:
- ✅ Automated spec compliance checking
- ✅ Four specialized review modes
- ✅ Multi-agent review support
- ✅ Structured, actionable feedback
- ✅ Review history tracking
- ✅ Integration with spec-driven workflow

Use it before every PR to ensure high-quality, spec-compliant code!
