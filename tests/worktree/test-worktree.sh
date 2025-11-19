#!/usr/bin/env bash
# ============================================================================
# Git Worktree Test Suite for SpecKit Plus
# ============================================================================
# Tests all worktree functionality including detection, creation, and
# integration with /sp.specify command.
#
# Usage:
#   ./test-worktree.sh              # Run all tests
#   ./test-worktree.sh --verbose    # Verbose output
#   ./test-worktree.sh --keep       # Keep test directories after run
#
# Requirements:
#   - Git 2.15+ (for worktree support)
#   - Bash 4.0+
#   - Write permissions in parent directory
# ============================================================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_BASE_DIR="${TEST_BASE_DIR:-/tmp/speckit-worktree-tests}"
# Resolve to physical path to avoid macOS /tmp vs /private/tmp mismatches
mkdir -p "$TEST_BASE_DIR"
TEST_BASE_DIR=$(cd "$TEST_BASE_DIR" && pwd -P)
VERBOSE=false
KEEP_TEST_DIRS=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --keep|-k)
            KEEP_TEST_DIRS=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --verbose, -v    Verbose output"
            echo "  --keep, -k       Keep test directories after run"
            echo "  --help, -h       Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${NC}       $*${NC}" >&2
    fi
}

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        log_error "$message"
        log_verbose "Expected: '$expected'"
        log_verbose "Actual:   '$actual'"
        CURRENT_TEST_FAILED=1
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-Assertion failed}"

    if [[ "$condition" == "true" ]] || [[ "$condition" == "0" ]]; then
        return 0
    else
        log_error "$message"
        log_verbose "Condition was false"
        CURRENT_TEST_FAILED=1
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-Assertion failed}"

    if [[ "$condition" == "false" ]] || [[ "$condition" != "0" ]]; then
        return 0
    else
        log_error "$message"
        log_verbose "Condition was true"
        CURRENT_TEST_FAILED=1
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File does not exist: $file}"

    if [[ -f "$file" ]]; then
        return 0
    else
        log_error "$message"
        CURRENT_TEST_FAILED=1
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory does not exist: $dir}"

    if [[ -d "$dir" ]]; then
        return 0
    else
        log_error "$message"
        CURRENT_TEST_FAILED=1
        return 1
    fi
}

assert_command_succeeds() {
    local message="$1"
    shift

    if "$@" >/dev/null 2>&1; then
        return 0
    else
        log_error "$message"
        log_verbose "Command failed: $*"
        CURRENT_TEST_FAILED=1
        return 1
    fi
}

assert_command_fails() {
    local message="$1"
    shift

    if ! "$@" >/dev/null 2>&1; then
        return 0
    else
        log_error "$message"
        log_verbose "Command succeeded when it should have failed: $*"
        CURRENT_TEST_FAILED=1
        return 1
    fi
}

# Run a test and track results
run_test() {
    local test_name="$1"
    local test_func="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    CURRENT_TEST_FAILED=0

    log_info "Running: $test_name"

    $test_func

    if [[ "$CURRENT_TEST_FAILED" -eq 0 ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_success "$test_name"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_error "$test_name"
        return 1
    fi
}

# ============================================================================
# Test Setup and Teardown
# ============================================================================

setup_test_environment() {
    log_info "Setting up test environment..."

    # Clean up any existing test directories
    if [[ -d "$TEST_BASE_DIR" ]]; then
        rm -rf "$TEST_BASE_DIR"
    fi

    mkdir -p "$TEST_BASE_DIR"
    cd "$TEST_BASE_DIR"
    TEST_BASE_DIR=$(pwd -P)

    log_verbose "Test directory: $TEST_BASE_DIR"
}

cleanup_test_environment() {
    if [[ "$KEEP_TEST_DIRS" == "false" ]]; then
        log_info "Cleaning up test environment..."
        cd /tmp
        rm -rf "$TEST_BASE_DIR"
        log_verbose "Removed: $TEST_BASE_DIR"
    else
        log_warning "Keeping test directories: $TEST_BASE_DIR"
    fi
}

create_test_repo() {
    local repo_name="$1"
    local repo_path="$TEST_BASE_DIR/$repo_name"

    mkdir -p "$repo_path"
    cd "$repo_path"

    git init -b main >/dev/null 2>&1
    git config user.email "test@speckit.test"
    git config user.name "SpecKit Test"

    # Copy SpecKit Plus structure
    mkdir -p specs history/prompts templates scripts/bash scripts/powershell

    # Copy common scripts
    cp "$REPO_ROOT/scripts/bash/common.sh" "$repo_path/scripts/bash/"
    cp "$REPO_ROOT/scripts/bash/create-new-feature.sh" "$repo_path/scripts/bash/"
    cp "$REPO_ROOT/scripts/powershell/common.ps1" "$repo_path/scripts/powershell/" 2>/dev/null || true

    # Copy templates
    cp -r "$REPO_ROOT/templates"/* "$repo_path/templates/" 2>/dev/null || true

    # Create initial commit
    echo "# Test Repository" > README.md
    git add -A >/dev/null 2>&1
    git commit -m "Initial commit" >/dev/null 2>&1

    log_verbose "Created test repo: $repo_path"
    # Return physical path to avoid /tmp vs /private/tmp mismatches on macOS
    cd "$repo_path" && pwd -P
}

# ============================================================================
# Unit Tests - Worktree Detection Functions
# ============================================================================

test_is_worktree_in_normal_repo() {
    local repo_path=$(create_test_repo "test-normal-repo")
    cd "$repo_path"

    source "$repo_path/scripts/bash/common.sh"

    # In normal repo, is_worktree should return false
    if is_worktree; then
        log_error "is_worktree() returned true in normal repo"
        return 1
    fi

    log_verbose "is_worktree() correctly returned false in normal repo"
    return 0
}

test_is_worktree_in_worktree() {
    local repo_path=$(create_test_repo "test-worktree-repo")
    cd "$repo_path"

    # Create a worktree
    mkdir -p "$TEST_BASE_DIR/worktrees"
    git worktree add "$TEST_BASE_DIR/worktrees/test-branch-is-worktree" -b test-branch-is-worktree >/dev/null 2>&1

    # Switch to worktree
    cd "$TEST_BASE_DIR/worktrees/test-branch-is-worktree"

    source "$repo_path/scripts/bash/common.sh"

    # In worktree, is_worktree should return true
    if ! is_worktree; then
        log_error "is_worktree() returned false in worktree"
        return 1
    fi

    log_verbose "is_worktree() correctly returned true in worktree"
    return 0
}

test_get_repo_root_in_normal_repo() {
    local repo_path=$(create_test_repo "test-repo-root-normal")
    cd "$repo_path"

    source "$repo_path/scripts/bash/common.sh"

    local detected_root=$(get_repo_root)

    assert_equals "$repo_path" "$detected_root" "get_repo_root() should return repo path in normal repo"
}

test_get_repo_root_in_worktree() {
    local repo_path=$(create_test_repo "test-repo-root-worktree")
    cd "$repo_path"

    # Create a worktree
    mkdir -p "$TEST_BASE_DIR/worktrees"
    git worktree add "$TEST_BASE_DIR/worktrees/test-branch-repo-root" -b test-branch-repo-root >/dev/null 2>&1

    # Switch to worktree
    cd "$TEST_BASE_DIR/worktrees/test-branch-repo-root"

    source "$repo_path/scripts/bash/common.sh"

    local detected_root=$(get_repo_root)

    # Should return main repo root, not worktree directory
    assert_equals "$repo_path" "$detected_root" "get_repo_root() should return main repo path in worktree, not worktree directory"
}

test_get_worktree_dir_in_worktree() {
    local repo_path=$(create_test_repo "test-worktree-dir")
    cd "$repo_path"

    # Create a worktree
    local worktree_path="$TEST_BASE_DIR/worktrees/test-branch-worktree-dir"
    mkdir -p "$TEST_BASE_DIR/worktrees"
    git worktree add "$worktree_path" -b test-branch-worktree-dir >/dev/null 2>&1

    # Switch to worktree
    cd "$worktree_path"

    source "$repo_path/scripts/bash/common.sh"

    local detected_dir=$(get_worktree_dir)

    assert_equals "$worktree_path" "$detected_dir" "get_worktree_dir() should return worktree directory"
}

test_get_git_common_dir() {
    local repo_path=$(create_test_repo "test-git-common-dir")
    cd "$repo_path"

    # Create a worktree
    mkdir -p "$TEST_BASE_DIR/worktrees"
    git worktree add "$TEST_BASE_DIR/worktrees/test-branch-common-dir" -b test-branch-common-dir >/dev/null 2>&1

    # Switch to worktree
    cd "$TEST_BASE_DIR/worktrees/test-branch-common-dir"

    source "$repo_path/scripts/bash/common.sh"

    local common_dir=$(get_git_common_dir)

    assert_equals "$repo_path" "$common_dir" "get_git_common_dir() should return main repo path"
}

# ============================================================================
# Unit Tests - Worktree Management Functions
# ============================================================================

test_create_worktree_new_branch() {
    local repo_path=$(create_test_repo "test-create-worktree")
    cd "$repo_path"

    source "$repo_path/scripts/bash/common.sh"

    local worktree_path=$(create_worktree "001-test-feature")
    local exit_code=$?

    assert_equals "0" "$exit_code" "create_worktree should succeed"
    assert_dir_exists "$worktree_path" "Worktree directory should exist"
    assert_command_succeeds "Branch should exist" git rev-parse --verify 001-test-feature

    log_verbose "Created worktree at: $worktree_path"
    return 0
}

test_create_worktree_existing_branch() {
    local repo_path=$(create_test_repo "test-create-worktree-existing")
    cd "$repo_path"

    source "$repo_path/scripts/bash/common.sh"

    # Create branch first
    git branch 002-existing-branch >/dev/null 2>&1

    local worktree_path=$(create_worktree "002-existing-branch")
    local exit_code=$?

    assert_equals "0" "$exit_code" "create_worktree should succeed with existing branch"
    assert_dir_exists "$worktree_path" "Worktree directory should exist"

    return 0
}

test_create_worktree_custom_path() {
    local repo_path=$(create_test_repo "test-create-worktree-custom")
    cd "$repo_path"

    source "$repo_path/scripts/bash/common.sh"

    local custom_path="$TEST_BASE_DIR/custom-location/my-worktree"
    mkdir -p "$(dirname "$custom_path")"

    local worktree_path=$(create_worktree "003-custom" "$custom_path")
    local exit_code=$?

    assert_equals "0" "$exit_code" "create_worktree should succeed with custom path"
    assert_equals "$custom_path" "$worktree_path" "Should use custom path"
    assert_dir_exists "$custom_path" "Worktree should exist at custom path"

    return 0
}

test_list_worktrees() {
    local repo_path=$(create_test_repo "test-list-worktrees")
    cd "$repo_path"

    source "$repo_path/scripts/bash/common.sh"

    # Create some worktrees
    create_worktree "001-feature-a" >/dev/null 2>&1
    create_worktree "002-feature-b" >/dev/null 2>&1

    local worktree_list=$(list_worktrees)

    if echo "$worktree_list" | grep -q "001-feature-a"; then
        log_verbose "Found feature-a in worktree list"
    else
        log_error "feature-a not found in worktree list"
        return 1
    fi

    if echo "$worktree_list" | grep -q "002-feature-b"; then
        log_verbose "Found feature-b in worktree list"
    else
        log_error "feature-b not found in worktree list"
        return 1
    fi

    return 0
}

test_remove_worktree() {
    local repo_path=$(create_test_repo "test-remove-worktree")
    cd "$repo_path"

    source "$repo_path/scripts/bash/common.sh"

    local worktree_path=$(create_worktree "004-to-remove")

    assert_dir_exists "$worktree_path" "Worktree should exist before removal"

    remove_worktree "$worktree_path" >/dev/null 2>&1

    if [[ -d "$worktree_path" ]]; then
        log_error "Worktree directory still exists after removal"
        return 1
    fi

    log_verbose "Worktree removed successfully"
    return 0
}

test_worktree_mode_enabled() {
    local repo_path=$(create_test_repo "test-worktree-mode")
    cd "$repo_path"

    source "$repo_path/scripts/bash/common.sh"

    # Test when disabled
    unset SPECIFY_WORKTREE_MODE
    if is_worktree_mode_enabled; then
        log_error "is_worktree_mode_enabled() should return false when not set"
        return 1
    fi

    # Test when enabled
    export SPECIFY_WORKTREE_MODE=true
    if ! is_worktree_mode_enabled; then
        log_error "is_worktree_mode_enabled() should return true when set to true"
        return 1
    fi

    log_verbose "is_worktree_mode_enabled() working correctly"
    return 0
}

# ============================================================================
# Integration Tests - specs/ and history/ Access
# ============================================================================

test_specs_dir_access_from_worktree() {
    local repo_path=$(create_test_repo "test-specs-access")
    cd "$repo_path"

    source "$repo_path/scripts/bash/common.sh"

    # Create a spec in main repo
    mkdir -p "$repo_path/specs/001-main-spec"
    echo "# Main Spec" > "$repo_path/specs/001-main-spec/spec.md"

    # Create worktree
    local worktree_path=$(create_worktree "002-worktree-branch")
    cd "$worktree_path"

    # Get repo root from worktree
    local detected_root=$(get_repo_root)
    local specs_dir="$detected_root/specs"

    # Should be able to access main spec from worktree
    assert_file_exists "$specs_dir/001-main-spec/spec.md" "Should access specs from main repo"

    # Create spec from worktree
    mkdir -p "$specs_dir/002-worktree-spec"
    echo "# Worktree Spec" > "$specs_dir/002-worktree-spec/spec.md"

    # Verify it's accessible from main repo
    cd "$repo_path"
    assert_file_exists "$repo_path/specs/002-worktree-spec/spec.md" "Spec created from worktree should exist in main repo"

    return 0
}

test_history_dir_access_from_worktree() {
    local repo_path=$(create_test_repo "test-history-access")
    cd "$repo_path"

    source "$repo_path/scripts/bash/common.sh"

    # Create history in main repo
    mkdir -p "$repo_path/history/prompts/001-main"
    echo "prompt1" > "$repo_path/history/prompts/001-main/prompt.md"

    # Create worktree
    local worktree_path=$(create_worktree "002-worktree-branch")
    cd "$worktree_path"

    # Get repo root from worktree
    local detected_root=$(get_repo_root)
    local history_dir="$detected_root/history"

    # Should access history from main repo
    assert_file_exists "$history_dir/prompts/001-main/prompt.md" "Should access history from main repo"

    # Create history from worktree
    mkdir -p "$history_dir/prompts/002-worktree"
    echo "prompt2" > "$history_dir/prompts/002-worktree/prompt.md"

    # Verify from main repo
    cd "$repo_path"
    assert_file_exists "$repo_path/history/prompts/002-worktree/prompt.md" "History created from worktree should exist in main repo"

    return 0
}

# ============================================================================
# Integration Tests - create-new-feature.sh with Worktrees
# ============================================================================

test_create_new_feature_normal_mode() {
    local repo_path=$(create_test_repo "test-create-feature-normal")
    cd "$repo_path"

    # Run create-new-feature.sh in normal mode
    local output=$("$repo_path/scripts/bash/create-new-feature.sh" --json --short-name "test-feature" --number 1 "Test feature description" 2>&1)

    # Should create branch, not worktree
    assert_command_succeeds "Branch should exist" git rev-parse --verify 001-test-feature
    assert_dir_exists "$repo_path/specs/001-test-feature" "Spec directory should exist"

    # Should be on the new branch
    local current_branch=$(git branch --show-current)
    assert_equals "001-test-feature" "$current_branch" "Should be on new branch"

    return 0
}

test_create_new_feature_worktree_mode() {
    local repo_path=$(create_test_repo "test-create-feature-worktree")
    cd "$repo_path"

    # Enable worktree mode
    export SPECIFY_WORKTREE_MODE=true

    # Run create-new-feature.sh
    local output=$("$repo_path/scripts/bash/create-new-feature.sh" --json --short-name "test-feature" --number 1 "Test feature description" 2>&1)

    # Should create worktree
    local worktree_path="$repo_path/../worktrees/001-test-feature"
    assert_dir_exists "$worktree_path" "Worktree should be created"
    assert_dir_exists "$repo_path/specs/001-test-feature" "Spec directory should exist in main repo"

    # Main repo should still be on main
    local main_branch=$(cd "$repo_path" && git branch --show-current)
    assert_equals "main" "$main_branch" "Main repo should remain on main branch"

    unset SPECIFY_WORKTREE_MODE
    return 0
}

# ============================================================================
# Edge Cases and Error Handling
# ============================================================================

test_create_worktree_without_git() {
    local test_dir="$TEST_BASE_DIR/no-git-repo"
    mkdir -p "$test_dir"
    cd "$test_dir"

    # Copy common.sh but don't initialize git
    mkdir -p scripts/bash
    cp "$REPO_ROOT/scripts/bash/common.sh" scripts/bash/

    source scripts/bash/common.sh

    # Should fail gracefully
    if create_worktree "test-branch" 2>/dev/null; then
        log_error "create_worktree should fail without git repo"
        return 1
    fi

    log_verbose "create_worktree correctly failed without git repo"
    return 0
}

test_create_worktree_empty_branch_name() {
    local repo_path=$(create_test_repo "test-empty-branch")
    cd "$repo_path"

    source "$repo_path/scripts/bash/common.sh"

    # Should fail with empty branch name
    if create_worktree "" 2>/dev/null; then
        log_error "create_worktree should fail with empty branch name"
        return 1
    fi

    log_verbose "create_worktree correctly failed with empty branch name"
    return 0
}

test_nested_worktree_detection() {
    local repo_path=$(create_test_repo "test-nested")
    cd "$repo_path"

    source "$repo_path/scripts/bash/common.sh"

    # Create worktree
    local worktree_path=$(create_worktree "001-parent")
    cd "$worktree_path"

    # Create subdirectory in worktree
    mkdir -p subdir/nested
    cd subdir/nested

    # Should still detect as worktree
    if ! is_worktree; then
        log_error "Should detect worktree from nested directory"
        return 1
    fi

    # Should still get correct repo root
    local detected_root=$(get_repo_root)
    assert_equals "$repo_path" "$detected_root" "Should get main repo root from nested directory in worktree"

    return 0
}

test_multiple_worktrees_simultaneously() {
    local repo_path=$(create_test_repo "test-multiple")
    cd "$repo_path"

    source "$repo_path/scripts/bash/common.sh"

    # Create multiple worktrees
    local wt1=$(create_worktree "001-feature-a")
    local wt2=$(create_worktree "002-feature-b")
    local wt3=$(create_worktree "003-feature-c")

    # All should exist
    assert_dir_exists "$wt1" "Worktree 1 should exist"
    assert_dir_exists "$wt2" "Worktree 2 should exist"
    assert_dir_exists "$wt3" "Worktree 3 should exist"

    # All should access same specs dir
    cd "$wt1"
    local root1=$(get_repo_root)

    cd "$wt2"
    local root2=$(get_repo_root)

    cd "$wt3"
    local root3=$(get_repo_root)

    assert_equals "$repo_path" "$root1" "Worktree 1 should get main repo root"
    assert_equals "$repo_path" "$root2" "Worktree 2 should get main repo root"
    assert_equals "$repo_path" "$root3" "Worktree 3 should get main repo root"

    return 0
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
    echo "============================================================================"
    echo "SpecKit Plus - Git Worktree Test Suite"
    echo "============================================================================"
    echo ""

    # Check git version
    # Extract git version (macOS compatible - no grep -P)
    local git_version=$(git --version | sed -n 's/^git version \([0-9]*\.[0-9]*\).*/\1/p')
    local git_major=$(echo "$git_version" | cut -d. -f1)
    local git_minor=$(echo "$git_version" | cut -d. -f2)

    if [[ $git_major -lt 2 ]] || [[ $git_major -eq 2 && $git_minor -lt 15 ]]; then
        log_error "Git 2.15+ required for worktree support (found: $git_version)"
        exit 1
    fi

    log_info "Git version: $git_version ✓"
    echo ""

    setup_test_environment

    # Run all tests
    echo "Running Unit Tests - Worktree Detection"
    echo "----------------------------------------"
    run_test "is_worktree() in normal repo" test_is_worktree_in_normal_repo
    run_test "is_worktree() in worktree" test_is_worktree_in_worktree
    run_test "get_repo_root() in normal repo" test_get_repo_root_in_normal_repo
    run_test "get_repo_root() in worktree" test_get_repo_root_in_worktree
    run_test "get_worktree_dir() in worktree" test_get_worktree_dir_in_worktree
    run_test "get_git_common_dir()" test_get_git_common_dir
    echo ""

    echo "Running Unit Tests - Worktree Management"
    echo "----------------------------------------"
    run_test "create_worktree() with new branch" test_create_worktree_new_branch
    run_test "create_worktree() with existing branch" test_create_worktree_existing_branch
    run_test "create_worktree() with custom path" test_create_worktree_custom_path
    run_test "list_worktrees()" test_list_worktrees
    run_test "remove_worktree()" test_remove_worktree
    run_test "is_worktree_mode_enabled()" test_worktree_mode_enabled
    echo ""

    echo "Running Integration Tests - File Access"
    echo "----------------------------------------"
    run_test "Access specs/ from worktree" test_specs_dir_access_from_worktree
    run_test "Access history/ from worktree" test_history_dir_access_from_worktree
    echo ""

    echo "Running Integration Tests - Scripts"
    echo "----------------------------------------"
    run_test "create-new-feature.sh normal mode" test_create_new_feature_normal_mode
    run_test "create-new-feature.sh worktree mode" test_create_new_feature_worktree_mode
    echo ""

    echo "Running Edge Cases and Error Handling"
    echo "----------------------------------------"
    run_test "create_worktree() without git" test_create_worktree_without_git
    run_test "create_worktree() with empty branch name" test_create_worktree_empty_branch_name
    run_test "Nested directory in worktree" test_nested_worktree_detection
    run_test "Multiple worktrees simultaneously" test_multiple_worktrees_simultaneously
    echo ""

    cleanup_test_environment

    # Print summary
    echo "============================================================================"
    echo "Test Summary"
    echo "============================================================================"
    echo -e "Tests run:    ${BLUE}$TESTS_RUN${NC}"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        return 1
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
