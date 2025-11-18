#!/usr/bin/env bash
# Test suite for /sp.review command

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Review script path
REVIEW_SCRIPT="$REPO_ROOT/scripts/bash/review-implementation.sh"

# Test helper functions
print_test_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo -e "${RED}✗ $message${NC}"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"

    if [[ -f "$file" ]]; then
        return 0
    else
        echo -e "${RED}✗ $message${NC}"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo -e "${RED}✗ $message${NC}"
        echo "  Expected to contain: $needle"
        echo "  In: $haystack"
        return 1
    fi
}

run_test() {
    local test_name="$1"
    TESTS_RUN=$((TESTS_RUN + 1))

    echo ""
    echo -e "${YELLOW}Running:${NC} $test_name"

    if "$2"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓ PASSED${NC}: $test_name"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗ FAILED${NC}: $test_name"
        return 1
    fi
}

# Setup test environment
setup_test_env() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"

    # Initialize git repo
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Create basic structure
    mkdir -p specs history .specify/templates

    # Create constitution
    cat > history/constitution.md << 'EOF'
# Project Constitution

## Code Quality Standards
- All code must have tests
- All functions must have documentation
- Follow style guide
EOF

    git add .
    git commit -q -m "Initial commit"

    echo "$TEST_DIR"
}

cleanup_test_env() {
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        cd "$REPO_ROOT"
        rm -rf "$TEST_DIR"
    fi
}

# =============================================================================
# Unit Tests - Script Validation
# =============================================================================

test_review_script_exists() {
    assert_file_exists "$REVIEW_SCRIPT" "Review script should exist"
}

test_review_script_executable() {
    if [[ -x "$REVIEW_SCRIPT" ]]; then
        return 0
    else
        echo -e "${RED}✗ Review script should be executable${NC}"
        return 1
    fi
}

test_review_help_output() {
    local output=$("$REVIEW_SCRIPT" --help 2>&1)

    assert_contains "$output" "Usage:" "Help should show usage" &&
    assert_contains "$output" "OPTIONS" "Help should show options" &&
    assert_contains "$output" "MODES" "Help should show modes" &&
    assert_contains "$output" "quick" "Help should mention quick mode" &&
    assert_contains "$output" "thorough" "Help should mention thorough mode" &&
    assert_contains "$output" "security" "Help should mention security mode" &&
    assert_contains "$output" "performance" "Help should mention performance mode"
}

# =============================================================================
# Unit Tests - Mode Detection
# =============================================================================

test_review_mode_quick() {
    TEST_DIR=$(setup_test_env)

    # Create feature branch
    git checkout -b 001-test-feature

    # Create spec and plan
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    # Run review in quick mode
    local output=$("$REVIEW_SCRIPT" --mode quick 2>&1 || true)

    cleanup_test_env

    assert_contains "$output" "Mode: quick" "Should run in quick mode"
}

test_review_mode_thorough() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    local output=$("$REVIEW_SCRIPT" --mode thorough 2>&1 || true)

    cleanup_test_env

    assert_contains "$output" "Mode: thorough" "Should run in thorough mode"
}

test_review_mode_security() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    local output=$("$REVIEW_SCRIPT" --mode security 2>&1 || true)

    cleanup_test_env

    assert_contains "$output" "Mode: security" "Should run in security mode"
}

test_review_mode_performance() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    local output=$("$REVIEW_SCRIPT" --mode performance 2>&1 || true)

    cleanup_test_env

    assert_contains "$output" "Mode: performance" "Should run in performance mode"
}

# =============================================================================
# Integration Tests - File Creation
# =============================================================================

test_review_creates_context_file() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    # Run review
    "$REVIEW_SCRIPT" --mode quick >/dev/null 2>&1 || true

    # Check context file exists
    local context_files=$(find specs/001-test-feature/reviews -name "*_context.md" 2>/dev/null | wc -l)

    cleanup_test_env

    if [[ $context_files -gt 0 ]]; then
        return 0
    else
        echo -e "${RED}✗ Should create context file${NC}"
        return 1
    fi
}

test_review_creates_review_file() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    # Run review
    "$REVIEW_SCRIPT" --mode quick >/dev/null 2>&1 || true

    # Check review file exists
    local review_files=$(find specs/001-test-feature/reviews -name "*_review.md" 2>/dev/null | wc -l)

    cleanup_test_env

    if [[ $review_files -gt 0 ]]; then
        return 0
    else
        echo -e "${RED}✗ Should create review file${NC}"
        return 1
    fi
}

test_review_context_includes_spec() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Specification" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    "$REVIEW_SCRIPT" --mode quick >/dev/null 2>&1 || true

    local context_file=$(find specs/001-test-feature/reviews -name "*_context.md" 2>/dev/null | head -1)
    local content=""
    if [[ -f "$context_file" ]]; then
        content=$(cat "$context_file")
    fi

    cleanup_test_env

    assert_contains "$content" "Feature Specification" "Context should include spec section" &&
    assert_contains "$content" "Test Specification" "Context should include spec content"
}

test_review_context_includes_plan() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Implementation Plan Details" > specs/001-test-feature/plan.md

    "$REVIEW_SCRIPT" --mode quick >/dev/null 2>&1 || true

    local context_file=$(find specs/001-test-feature/reviews -name "*_context.md" 2>/dev/null | head -1)
    local content=""
    if [[ -f "$context_file" ]]; then
        content=$(cat "$context_file")
    fi

    cleanup_test_env

    assert_contains "$content" "Implementation Plan" "Context should include plan section" &&
    assert_contains "$content" "Implementation Plan Details" "Context should include plan content"
}

test_review_context_includes_constitution() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    "$REVIEW_SCRIPT" --mode quick >/dev/null 2>&1 || true

    local context_file=$(find specs/001-test-feature/reviews -name "*_context.md" 2>/dev/null | head -1)
    local content=""
    if [[ -f "$context_file" ]]; then
        content=$(cat "$context_file")
    fi

    cleanup_test_env

    assert_contains "$content" "Constitution" "Context should include constitution section" &&
    assert_contains "$content" "Code Quality Standards" "Context should include constitution content"
}

# =============================================================================
# Integration Tests - Agent Parameter
# =============================================================================

test_review_agent_parameter() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    local output=$("$REVIEW_SCRIPT" --mode quick --agent gemini 2>&1 || true)

    # Check that files include agent name
    local gemini_files=$(find specs/001-test-feature/reviews -name "*gemini*" 2>/dev/null | wc -l)

    cleanup_test_env

    if [[ $gemini_files -gt 0 ]]; then
        return 0
    else
        echo -e "${RED}✗ Should create files with agent name${NC}"
        return 1
    fi
}

test_review_default_agent() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    local output=$("$REVIEW_SCRIPT" --mode quick 2>&1 || true)

    # Should use current user as default agent
    local user_files=$(find specs/001-test-feature/reviews -name "*$(whoami)*" 2>/dev/null | wc -l)

    cleanup_test_env

    if [[ $user_files -gt 0 ]]; then
        return 0
    else
        echo -e "${RED}✗ Should use current user as default agent${NC}"
        return 1
    fi
}

# =============================================================================
# Integration Tests - JSON Output
# =============================================================================

test_review_json_output() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    local output=$("$REVIEW_SCRIPT" --mode quick --json 2>&1 || true)

    cleanup_test_env

    # Check if output is valid JSON
    if echo "$output" | python3 -m json.tool >/dev/null 2>&1; then
        assert_contains "$output" "review_id" "JSON should contain review_id" &&
        assert_contains "$output" "context_file" "JSON should contain context_file" &&
        assert_contains "$output" "review_file" "JSON should contain review_file"
    else
        echo -e "${RED}✗ Output should be valid JSON${NC}"
        return 1
    fi
}

# =============================================================================
# Error Handling Tests
# =============================================================================

test_review_error_no_spec() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    # Don't create spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    local output=$("$REVIEW_SCRIPT" --mode quick 2>&1 || true)
    local exit_code=$?

    cleanup_test_env

    if [[ $exit_code -ne 0 ]]; then
        assert_contains "$output" "Spec not found" "Should error when spec missing"
    else
        echo -e "${RED}✗ Should fail when spec is missing${NC}"
        return 1
    fi
}

test_review_error_no_plan() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    # Don't create plan.md

    local output=$("$REVIEW_SCRIPT" --mode quick 2>&1 || true)
    local exit_code=$?

    cleanup_test_env

    if [[ $exit_code -ne 0 ]]; then
        assert_contains "$output" "Plan not found" "Should error when plan missing"
    else
        echo -e "${RED}✗ Should fail when plan is missing${NC}"
        return 1
    fi
}

test_review_error_not_feature_branch() {
    TEST_DIR=$(setup_test_env)

    # Stay on main branch
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    local output=$("$REVIEW_SCRIPT" --mode quick 2>&1 || true)
    local exit_code=$?

    cleanup_test_env

    if [[ $exit_code -ne 0 ]]; then
        return 0
    else
        echo -e "${RED}✗ Should fail when not on feature branch${NC}"
        return 1
    fi
}

# =============================================================================
# Advanced Tests - Tasks Integration
# =============================================================================

test_review_includes_tasks_if_exists() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md
    echo "# Test Tasks" > specs/001-test-feature/tasks.md

    "$REVIEW_SCRIPT" --mode quick >/dev/null 2>&1 || true

    local context_file=$(find specs/001-test-feature/reviews -name "*_context.md" 2>/dev/null | head -1)
    local content=""
    if [[ -f "$context_file" ]]; then
        content=$(cat "$context_file")
    fi

    cleanup_test_env

    assert_contains "$content" "Implementation Tasks" "Context should include tasks section" &&
    assert_contains "$content" "Test Tasks" "Context should include tasks content"
}

test_review_skips_tasks_if_missing() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md
    # Don't create tasks.md

    "$REVIEW_SCRIPT" --mode quick >/dev/null 2>&1 || true

    local context_file=$(find specs/001-test-feature/reviews -name "*_context.md" 2>/dev/null | head -1)
    local json_output=$("$REVIEW_SCRIPT" --mode quick --json 2>&1 || true)

    cleanup_test_env

    # Check JSON indicates tasks don't exist
    assert_contains "$json_output" '"tasks_exist":false' "JSON should indicate tasks don't exist"
}

# =============================================================================
# Advanced Tests - Data Model Integration
# =============================================================================

test_review_includes_data_model_if_exists() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md
    echo "# Data Model Schema" > specs/001-test-feature/data-model.md

    "$REVIEW_SCRIPT" --mode quick >/dev/null 2>&1 || true

    local context_file=$(find specs/001-test-feature/reviews -name "*_context.md" 2>/dev/null | head -1)
    local content=""
    if [[ -f "$context_file" ]]; then
        content=$(cat "$context_file")
    fi

    cleanup_test_env

    assert_contains "$content" "Data Model" "Context should include data model section" &&
    assert_contains "$content" "Data Model Schema" "Context should include data model content"
}

# =============================================================================
# Review Template Tests
# =============================================================================

test_review_template_structure() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    "$REVIEW_SCRIPT" --mode quick >/dev/null 2>&1 || true

    local review_file=$(find specs/001-test-feature/reviews -name "*_review.md" 2>/dev/null | head -1)
    local content=""
    if [[ -f "$review_file" ]]; then
        content=$(cat "$review_file")
    fi

    cleanup_test_env

    assert_contains "$content" "## Summary" "Review should have Summary section" &&
    assert_contains "$content" "## Spec Compliance" "Review should have Spec Compliance section" &&
    assert_contains "$content" "## Quality Assessment" "Review should have Quality Assessment section" &&
    assert_contains "$content" "## Issues Found" "Review should have Issues Found section" &&
    assert_contains "$content" "## Overall Assessment" "Review should have Overall Assessment section"
}

test_review_template_has_checklist() {
    TEST_DIR=$(setup_test_env)

    git checkout -b 001-test-feature
    mkdir -p specs/001-test-feature
    echo "# Test Spec" > specs/001-test-feature/spec.md
    echo "# Test Plan" > specs/001-test-feature/plan.md

    "$REVIEW_SCRIPT" --mode quick >/dev/null 2>&1 || true

    local review_file=$(find specs/001-test-feature/reviews -name "*_review.md" 2>/dev/null | head -1)
    local content=""
    if [[ -f "$review_file" ]]; then
        content=$(cat "$review_file")
    fi

    cleanup_test_env

    assert_contains "$content" "- [ ]" "Review should have checklist items"
}

# =============================================================================
# Run All Tests
# =============================================================================

main() {
    print_test_header "SpecKit Plus Review Command Test Suite"

    echo "Repository: $REPO_ROOT"
    echo "Review Script: $REVIEW_SCRIPT"

    # Unit Tests - Script Validation
    print_test_header "Unit Tests - Script Validation"
    run_test "Review script exists" test_review_script_exists
    run_test "Review script is executable" test_review_script_executable
    run_test "Review script shows help" test_review_help_output

    # Unit Tests - Mode Detection
    print_test_header "Unit Tests - Mode Detection"
    run_test "Review mode: quick" test_review_mode_quick
    run_test "Review mode: thorough" test_review_mode_thorough
    run_test "Review mode: security" test_review_mode_security
    run_test "Review mode: performance" test_review_mode_performance

    # Integration Tests - File Creation
    print_test_header "Integration Tests - File Creation"
    run_test "Review creates context file" test_review_creates_context_file
    run_test "Review creates review file" test_review_creates_review_file
    run_test "Context includes spec" test_review_context_includes_spec
    run_test "Context includes plan" test_review_context_includes_plan
    run_test "Context includes constitution" test_review_context_includes_constitution

    # Integration Tests - Agent Parameter
    print_test_header "Integration Tests - Agent Parameter"
    run_test "Review with custom agent" test_review_agent_parameter
    run_test "Review with default agent" test_review_default_agent

    # Integration Tests - JSON Output
    print_test_header "Integration Tests - JSON Output"
    run_test "Review JSON output" test_review_json_output

    # Error Handling Tests
    print_test_header "Error Handling Tests"
    run_test "Review errors when spec missing" test_review_error_no_spec
    run_test "Review errors when plan missing" test_review_error_no_plan
    run_test "Review errors when not on feature branch" test_review_error_not_feature_branch

    # Advanced Tests - Tasks Integration
    print_test_header "Advanced Tests - Tasks Integration"
    run_test "Review includes tasks if exists" test_review_includes_tasks_if_exists
    run_test "Review skips tasks if missing" test_review_skips_tasks_if_missing

    # Advanced Tests - Data Model Integration
    print_test_header "Advanced Tests - Data Model"
    run_test "Review includes data model if exists" test_review_includes_data_model_if_exists

    # Review Template Tests
    print_test_header "Review Template Tests"
    run_test "Review template has correct structure" test_review_template_structure
    run_test "Review template has checklist" test_review_template_has_checklist

    # Summary
    print_test_header "Test Summary"
    echo ""
    echo "Tests Run:    $TESTS_RUN"
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
