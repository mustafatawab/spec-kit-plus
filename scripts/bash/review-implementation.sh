#!/usr/bin/env bash

# review-implementation.sh - Review implementation against spec, plan, and tasks
#
# This script gathers all context and prepares it for AI review:
# - Constitution (if exists)
# - Spec (requirements, success criteria)
# - Plan (technical design)
# - Tasks (implementation checklist)
# - Actual code implementation
#
# Usage:
#   scripts/bash/review-implementation.sh [--json] [--mode <mode>] [--agent <name>]
#
# Modes:
#   - quick: Fast compliance check (default)
#   - thorough: Deep review of implementation quality
#   - security: Security-focused review
#   - performance: Performance optimization review

set -e

# Parse command line arguments
JSON_MODE=false
REVIEW_MODE="quick"
AGENT_NAME="default"
INCLUDE_DIFF=false

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --mode)
            shift
            REVIEW_MODE="$1"
            ;;
        --agent)
            shift
            AGENT_NAME="$1"
            ;;
        --include-diff)
            INCLUDE_DIFF=true
            ;;
        --help|-h)
            cat << 'EOF'
Usage: review-implementation.sh [OPTIONS]

Review implementation against spec, plan, and tasks.

OPTIONS:
  --json              Output in JSON format
  --mode <mode>       Review mode: quick|thorough|security|performance
  --agent <name>      Agent name for tracking (default: current user)
  --include-diff      Include git diff in review context
  --help, -h          Show this help message

MODES:
  quick       Fast compliance check (5-10 min)
  thorough    Deep review of implementation quality (20-30 min)
  security    Security-focused review (15-20 min)
  performance Performance optimization review (15-20 min)

EXAMPLES:
  # Quick review before PR
  ./review-implementation.sh --mode quick

  # Thorough review with different agent
  ./review-implementation.sh --mode thorough --agent gemini

  # Security review with git diff
  ./review-implementation.sh --mode security --include-diff

EOF
            exit 0
            ;;
        *)
            shift
            ;;
    esac
    shift
done

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Get feature paths and validate branch
eval $(get_feature_paths)
check_feature_branch "$CURRENT_BRANCH" "$HAS_GIT" || exit 1

# Validate mode
case "$REVIEW_MODE" in
    quick|thorough|security|performance)
        # Valid mode
        ;;
    *)
        echo "ERROR: Invalid review mode: $REVIEW_MODE" >&2
        echo "Valid modes: quick, thorough, security, performance" >&2
        exit 1
        ;;
esac

# Check prerequisites
if [[ ! -f "$FEATURE_SPEC" ]]; then
    echo "ERROR: Spec not found: $FEATURE_SPEC" >&2
    echo "Run /sp.specify first to create the specification." >&2
    exit 1
fi

if [[ ! -f "$IMPL_PLAN" ]]; then
    echo "ERROR: Plan not found: $IMPL_PLAN" >&2
    echo "Run /sp.plan first to create the implementation plan." >&2
    exit 1
fi

# Optional: Tasks file (not required for review, but helpful)
TASKS_EXIST=false
if [[ -f "$TASKS" ]]; then
    TASKS_EXIST=true
fi

# Gather review context
REVIEW_DIR="$FEATURE_DIR/reviews"
mkdir -p "$REVIEW_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REVIEW_ID="${TIMESTAMP}_${REVIEW_MODE}_${AGENT_NAME}"
CONTEXT_FILE="$REVIEW_DIR/${REVIEW_ID}_context.md"

# Create review context document
cat > "$CONTEXT_FILE" << EOF
# Code Review Context: $CURRENT_BRANCH

**Review ID:** $REVIEW_ID
**Mode:** $REVIEW_MODE
**Agent:** $AGENT_NAME
**Timestamp:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Branch:** $CURRENT_BRANCH

---

## Review Objectives

EOF

# Add mode-specific objectives
case "$REVIEW_MODE" in
    quick)
        cat >> "$CONTEXT_FILE" << 'EOF'
### Quick Review Objectives
- Verify all spec requirements are implemented
- Check that success criteria are met
- Identify obvious bugs or issues
- Ensure basic quality standards
- Review time: 5-10 minutes

EOF
        ;;
    thorough)
        cat >> "$CONTEXT_FILE" << 'EOF'
### Thorough Review Objectives
- Deep analysis of code quality
- Architecture alignment with plan
- Test coverage verification
- Error handling completeness
- Documentation quality
- Performance considerations
- Review time: 20-30 minutes

EOF
        ;;
    security)
        cat >> "$CONTEXT_FILE" << 'EOF'
### Security Review Objectives
- Input validation and sanitization
- Authentication and authorization
- SQL injection prevention
- XSS vulnerability check
- CSRF protection
- Secrets management
- Dependency vulnerabilities
- Review time: 15-20 minutes

EOF
        ;;
    performance)
        cat >> "$CONTEXT_FILE" << 'EOF'
### Performance Review Objectives
- Algorithm efficiency
- Database query optimization
- Caching opportunities
- Memory usage
- Network request optimization
- Bundle size (frontend)
- Review time: 15-20 minutes

EOF
        ;;
esac

# Add Constitution if exists
CONSTITUTION_FILE="$REPO_ROOT/history/constitution.md"
if [[ -f "$CONSTITUTION_FILE" ]]; then
    cat >> "$CONTEXT_FILE" << EOF
## Constitution (Quality Guidelines)

\`\`\`markdown
$(cat "$CONSTITUTION_FILE")
\`\`\`

---

EOF
fi

# Add Specification
cat >> "$CONTEXT_FILE" << EOF
## Feature Specification

**File:** \`$FEATURE_SPEC\`

\`\`\`markdown
$(cat "$FEATURE_SPEC")
\`\`\`

---

EOF

# Add Implementation Plan
cat >> "$CONTEXT_FILE" << EOF
## Implementation Plan

**File:** \`$IMPL_PLAN\`

\`\`\`markdown
$(cat "$IMPL_PLAN")
\`\`\`

---

EOF

# Add Tasks if exists
if [[ "$TASKS_EXIST" == "true" ]]; then
    cat >> "$CONTEXT_FILE" << EOF
## Implementation Tasks

**File:** \`$TASKS\`

\`\`\`markdown
$(cat "$TASKS")
\`\`\`

---

EOF
fi

# Add Data Model if exists
DATA_MODEL_FILE="$FEATURE_DIR/data-model.md"
if [[ -f "$DATA_MODEL_FILE" ]]; then
    cat >> "$CONTEXT_FILE" << EOF
## Data Model

**File:** \`$DATA_MODEL_FILE\`

\`\`\`markdown
$(cat "$DATA_MODEL_FILE")
\`\`\`

---

EOF
fi

# Add git diff if requested
if [[ "$INCLUDE_DIFF" == "true" && "$HAS_GIT" == "true" ]]; then
    cat >> "$CONTEXT_FILE" << EOF
## Code Changes (Git Diff)

**Compared to:** main branch

\`\`\`diff
$(git diff main...HEAD 2>/dev/null || echo "Unable to generate diff")
\`\`\`

---

EOF
fi

# Add file tree of implementation
cat >> "$CONTEXT_FILE" << EOF
## Implementation Files

**Working Directory:** $(pwd)

\`\`\`
$(find . -type f \
    -not -path "*/\.*" \
    -not -path "*/node_modules/*" \
    -not -path "*/dist/*" \
    -not -path "*/build/*" \
    -not -path "*/__pycache__/*" \
    -not -path "*/venv/*" \
    2>/dev/null | head -100)
\`\`\`

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

EOF

# Create review template file
REVIEW_FILE="$REVIEW_DIR/${REVIEW_ID}_review.md"

cat > "$REVIEW_FILE" << EOF
# Code Review: $CURRENT_BRANCH

**Review ID:** $REVIEW_ID
**Date:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Mode:** $REVIEW_MODE
**Reviewer:** $AGENT_NAME

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
1. **File:** \`path/to/file.ts:123\`
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

EOF

# Output results
if $JSON_MODE; then
    printf '{"review_id":"%s","mode":"%s","context_file":"%s","review_file":"%s","spec_file":"%s","plan_file":"%s","tasks_file":"%s","tasks_exist":"%s"}\n' \
        "$REVIEW_ID" "$REVIEW_MODE" "$CONTEXT_FILE" "$REVIEW_FILE" "$FEATURE_SPEC" "$IMPL_PLAN" "$TASKS" "$TASKS_EXIST"
else
    echo "✅ Review context prepared"
    echo ""
    echo "Review ID: $REVIEW_ID"
    echo "Mode: $REVIEW_MODE"
    echo ""
    echo "Context file: $CONTEXT_FILE"
    echo "Review file: $REVIEW_FILE"
    echo ""
    echo "Next steps:"
    echo "1. Read the context file to understand what needs review"
    echo "2. Examine the code implementation"
    echo "3. Fill out the review template with your findings"
    echo "4. Save the completed review"
    echo ""
    if [[ "$AGENT_NAME" != "$(whoami)" ]]; then
        echo "Note: Review agent ($AGENT_NAME) is different from current user"
        echo "This provides a fresh perspective on the implementation."
    fi
fi
