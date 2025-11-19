#!/usr/bin/env bash
# Common functions and variables for all scripts

# Check if we're in a git worktree (not the main working tree)
is_worktree() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 1  # Not in a git repo
    fi

    local git_dir=$(git rev-parse --git-dir 2>/dev/null)
    # In a worktree, .git is a file, not a directory
    # Or git-dir contains "worktrees"
    [[ -f "$git_dir" ]] || [[ "$git_dir" == *"/worktrees/"* ]]
}

# Get the main repository root (not worktree directory)
# This is where specs/, history/, templates/ should be accessed from
get_git_common_dir() {
    if ! git rev-parse --git-common-dir >/dev/null 2>&1; then
        return 1
    fi

    local common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    # Get the parent of .git directory
    (cd "$common_dir/.." && pwd)
}

# Get repository root, with fallback for non-git repositories
# In worktree mode, this returns the MAIN repo root (where specs/ lives)
# Not the worktree directory
get_repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        # Check if we're in a worktree
        if is_worktree; then
            # Return main repo root, not worktree directory
            get_git_common_dir
        else
            # Normal git repo
            git rev-parse --show-toplevel
        fi
    else
        # Fall back to script location for non-git repos
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        (cd "$script_dir/../../.." && pwd)
    fi
}

# Get current worktree directory (where we're currently working)
get_worktree_dir() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        pwd
    fi
}

# Get current branch, with fallback for non-git repositories
get_current_branch() {
    # First check if SPECIFY_FEATURE environment variable is set
    if [[ -n "${SPECIFY_FEATURE:-}" ]]; then
        echo "$SPECIFY_FEATURE"
        return
    fi

    # Then check git if available
    if git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
        git rev-parse --abbrev-ref HEAD
        return
    fi

    # For non-git repos, try to find the latest feature directory
    local repo_root=$(get_repo_root)
    local specs_dir="$repo_root/specs"

    if [[ -d "$specs_dir" ]]; then
        local latest_feature=""
        local highest=0

        for dir in "$specs_dir"/*; do
            if [[ -d "$dir" ]]; then
                local dirname=$(basename "$dir")
                if [[ "$dirname" =~ ^([0-9]{3})- ]]; then
                    local number=${BASH_REMATCH[1]}
                    number=$((10#$number))
                    if [[ "$number" -gt "$highest" ]]; then
                        highest=$number
                        latest_feature=$dirname
                    fi
                fi
            fi
        done

        if [[ -n "$latest_feature" ]]; then
            echo "$latest_feature"
            return
        fi
    fi

    echo "main"  # Final fallback
}

# Check if we have git available
has_git() {
    git rev-parse --show-toplevel >/dev/null 2>&1
}

check_feature_branch() {
    local branch="$1"
    local has_git_repo="$2"

    # For non-git repos, we can't enforce branch naming but still provide output
    if [[ "$has_git_repo" != "true" ]]; then
        echo "[specify] Warning: Git repository not detected; skipped branch validation" >&2
        return 0
    fi

    # Check for detached HEAD state
    if [[ "$branch" == "HEAD" ]]; then
        echo "ERROR: Currently in detached HEAD state" >&2
        echo "" >&2
        echo "Please checkout or create a feature branch first:" >&2
        echo "  git checkout -b 001-feature-name" >&2
        echo "  or" >&2
        echo "  git checkout main  # return to main branch" >&2
        return 1
    fi

    if [[ ! "$branch" =~ ^[0-9]{3}- ]]; then
        echo "ERROR: Not on a feature branch. Current branch: $branch" >&2
        echo "Feature branches should be named like: 001-feature-name" >&2
        return 1
    fi

    return 0
}

get_feature_dir() { echo "$1/specs/$2"; }

# Find feature directory by numeric prefix instead of exact branch match
# This allows multiple branches to work on the same spec (e.g., 004-fix-bug, 004-add-feature)
find_feature_dir_by_prefix() {
    local repo_root="$1"
    local branch_name="$2"
    local specs_dir="$repo_root/specs"

    # Extract numeric prefix from branch (e.g., "004" from "004-whatever")
    if [[ ! "$branch_name" =~ ^([0-9]{3})- ]]; then
        # If branch doesn't have numeric prefix, fall back to exact match
        echo "$specs_dir/$branch_name"
        return
    fi

    local prefix="${BASH_REMATCH[1]}"

    # Search for directories in specs/ that start with this prefix
    local matches=()
    if [[ -d "$specs_dir" ]]; then
        for dir in "$specs_dir"/"$prefix"-*; do
            if [[ -d "$dir" ]]; then
                matches+=("$(basename "$dir")")
            fi
        done
    fi

    # Handle results
    if [[ ${#matches[@]} -eq 0 ]]; then
        # No match found - return the branch name path (will fail later with clear error)
        echo "$specs_dir/$branch_name"
    elif [[ ${#matches[@]} -eq 1 ]]; then
        # Exactly one match - perfect!
        echo "$specs_dir/${matches[0]}"
    else
        # Multiple matches - this shouldn't happen with proper naming convention
        echo "ERROR: Multiple spec directories found with prefix '$prefix': ${matches[*]}" >&2
        echo "Please ensure only one spec directory exists per numeric prefix." >&2
        echo "$specs_dir/$branch_name"  # Return something to avoid breaking the script
    fi
}

# Ensure repository structure exists
ensure_repo_structure() {
    local repo_root=$(get_repo_root)

    # Create required directories if missing
    mkdir -p "$repo_root/specs" "$repo_root/history"

    # Create .gitkeep files to track empty directories
    if [[ ! -f "$repo_root/specs/.gitkeep" ]]; then
        touch "$repo_root/specs/.gitkeep"
    fi
    if [[ ! -f "$repo_root/history/.gitkeep" ]]; then
        touch "$repo_root/history/.gitkeep"
    fi
}

get_feature_paths() {
    local repo_root=$(get_repo_root)
    local current_branch=$(get_current_branch)
    local has_git_repo="false"

    if has_git; then
        has_git_repo="true"
    fi

    # Ensure specs/ and history/ exist
    ensure_repo_structure

    # Use prefix-based lookup to support multiple branches per spec
    local feature_dir=$(find_feature_dir_by_prefix "$repo_root" "$current_branch")

    cat <<EOF
REPO_ROOT='$repo_root'
CURRENT_BRANCH='$current_branch'
HAS_GIT='$has_git_repo'
FEATURE_DIR='$feature_dir'
FEATURE_SPEC='$feature_dir/spec.md'
IMPL_PLAN='$feature_dir/plan.md'
TASKS='$feature_dir/tasks.md'
RESEARCH='$feature_dir/research.md'
DATA_MODEL='$feature_dir/data-model.md'
QUICKSTART='$feature_dir/quickstart.md'
CONTRACTS_DIR='$feature_dir/contracts'
EOF
}

check_file() { [[ -f "$1" ]] && echo "  ✓ $2" || echo "  ✗ $2"; }
check_dir() { [[ -d "$1" && -n $(ls -A "$1" 2>/dev/null) ]] && echo "  ✓ $2" || echo "  ✗ $2"; }

# ============================================================================
# Git Worktree Functions
# ============================================================================

# List all git worktrees
list_worktrees() {
    if ! has_git; then
        echo "ERROR: Not in a git repository" >&2
        return 1
    fi

    git worktree list
}

# Validate branch name according to git-check-ref-format rules
validate_branch_name() {
    local name="$1"

    # Check for spaces
    if [[ "$name" =~ [[:space:]] ]]; then
        echo "ERROR: Branch name cannot contain spaces" >&2
        echo "Use hyphens instead: ${name// /-}" >&2
        return 1
    fi

    # Check length (Git ref limit is ~255, but we use 200 for safety)
    if [[ ${#name} -gt 200 ]]; then
        echo "ERROR: Branch name too long (max 200 characters)" >&2
        echo "Current length: ${#name}" >&2
        return 1
    fi

    # Check invalid characters per git-check-ref-format
    if [[ "$name" =~ [\[\]^~:?*\\] ]] || [[ "$name" == *.. ]] || [[ "$name" == .* ]] || [[ "$name" == *. ]]; then
        echo "ERROR: Branch name contains invalid characters" >&2
        echo "Avoid: spaces [ ] ^ ~ : ? * \\ .. (leading/trailing dots)" >&2
        return 1
    fi

    # Check for leading/trailing slashes or multiple consecutive slashes
    if [[ "$name" == /* ]] || [[ "$name" == */ ]] || [[ "$name" == *//* ]]; then
        echo "ERROR: Branch name has invalid slash usage" >&2
        return 1
    fi

    return 0
}

# Create a new git worktree for a feature branch
# Usage: create_worktree <branch-name> [worktree-path]
create_worktree() {
    local branch_name="$1"
    local worktree_path="${2:-}"

    if ! has_git; then
        echo "ERROR: Not in a git repository" >&2
        echo "" >&2
        echo "Worktrees require a git repository. Initialize one with:" >&2
        echo "  git init" >&2
        return 1
    fi

    if [[ -z "$branch_name" ]]; then
        echo "ERROR: Branch name required" >&2
        echo "" >&2
        echo "Usage: create_worktree <branch-name> [worktree-path]" >&2
        echo "" >&2
        echo "Example:" >&2
        echo "  create_worktree 001-user-auth" >&2
        echo "  create_worktree 002-dashboard ../my-worktrees/dashboard" >&2
        return 1
    fi

    # Validate branch name
    validate_branch_name "$branch_name" || return 1

    # Get repo root for default path
    local repo_root=$(get_repo_root)

    # Default worktree path: ../worktrees/<branch-name>
    if [[ -z "$worktree_path" ]]; then
        local worktrees_dir="$repo_root/../worktrees"
        mkdir -p "$worktrees_dir"
        worktree_path="$worktrees_dir/$branch_name"
    fi

    # Check if worktree path already exists
    if [[ -e "$worktree_path" ]]; then
        echo "ERROR: Path already exists: $worktree_path" >&2
        if [[ -d "$worktree_path" ]]; then
            echo "Remove the directory first:" >&2
            echo "  rm -rf '$worktree_path'" >&2
            echo "Or choose a different path" >&2
        fi
        return 1
    fi

    # Check if branch already exists
    if git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
        # Branch exists, create worktree from it
        echo "Creating worktree for existing branch '$branch_name'..." >&2
        git worktree add "$worktree_path" "$branch_name"
    else
        # Create new branch and worktree
        echo "Creating new branch '$branch_name' and worktree..." >&2
        git worktree add -b "$branch_name" "$worktree_path"
    fi

    if [[ $? -eq 0 ]]; then
        echo "$worktree_path"
        return 0
    else
        return 1
    fi
}

# Remove a git worktree
# Usage: remove_worktree <worktree-path>
remove_worktree() {
    local worktree_path="$1"

    if ! has_git; then
        echo "ERROR: Not in a git repository" >&2
        return 1
    fi

    if [[ -z "$worktree_path" ]]; then
        echo "ERROR: Worktree path required" >&2
        echo "" >&2
        echo "Usage: remove_worktree <worktree-path>" >&2
        echo "" >&2
        echo "To list existing worktrees:" >&2
        echo "  git worktree list" >&2
        return 1
    fi

    # Check if worktree has uncommitted changes
    if [[ -d "$worktree_path" ]] && git -C "$worktree_path" status --porcelain 2>/dev/null | grep -q .; then
        echo "WARNING: Worktree has uncommitted changes:" >&2
        git -C "$worktree_path" status --short >&2
        echo "" >&2
        read -p "Continue with removal? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Aborted." >&2
            return 1
        fi
    fi

    git worktree remove "$worktree_path"
}

# Prune stale worktree references
prune_worktrees() {
    if ! has_git; then
        echo "ERROR: Not in a git repository" >&2
        return 1
    fi

    git worktree prune
}

# Check if worktree mode is enabled
# Checks for SPECIFY_WORKTREE_MODE environment variable
is_worktree_mode_enabled() {
    [[ "${SPECIFY_WORKTREE_MODE:-false}" == "true" ]]
}

