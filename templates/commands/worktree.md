# Git Worktree Management

You are a git worktree management assistant. Execute the following steps based on user's request:

## Command Modes

Detect the user's intent from their message:

- **List worktrees**: "list", "show worktrees", "what worktrees exist"
- **Create worktree**: "create", "new worktree for feature X", "setup worktree"
- **Remove worktree**: "remove", "delete worktree", "cleanup"
- **Enable worktree mode**: "enable", "turn on worktree mode"
- **Help/Info**: "help", "how to use", no specific request

## Execution Steps

### 1. List Worktrees

When user wants to list worktrees:

```bash
# Get repo root (worktree-aware)
SCRIPT_DIR="$PWD"
if [ -f "scripts/bash/common.sh" ]; then
    source scripts/bash/common.sh
    cd "$(get_repo_root)"
else
    cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
git worktree list
```

Show output in a clear format with:
- Main repository path
- All worktree paths
- Associated branches

### 2. Create New Worktree

When user wants to create a new worktree:

a. **Determine the branch name**:
   - If user provides feature description, generate branch name like: `NNN-feature-name`
   - Check existing specs to determine next number
   - If user provides explicit branch name, use it

b. **Determine worktree location**:
   - Default: `../worktrees/<branch-name>` (sibling to main repo)
   - User can override with specific path

c. **Create the worktree**:

```bash
# Source common functions first for worktree-aware operations
SCRIPT_DIR="$PWD"
if [ -f "scripts/bash/common.sh" ]; then
    source scripts/bash/common.sh
    REPO_ROOT="$(get_repo_root)"
elif [ -f "$SCRIPT_DIR/scripts/bash/common.sh" ]; then
    source "$SCRIPT_DIR/scripts/bash/common.sh"
    REPO_ROOT="$(get_repo_root)"
else
    # Fallback if common.sh not found
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

# Create worktree
BRANCH_NAME="NNN-feature-name"  # Use actual branch name
WORKTREE_PATH=$(create_worktree "$BRANCH_NAME")

if [[ $? -eq 0 ]]; then
    echo "✓ Worktree created successfully!"
    echo "  Branch: $BRANCH_NAME"
    echo "  Path: $WORKTREE_PATH"
    echo ""
    echo "To switch to this worktree:"
    echo "  cd $WORKTREE_PATH"
else
    echo "✗ Failed to create worktree"
    exit 1
fi
```

d. **Check if spec already exists**:
   - If creating worktree for existing feature number, inform user
   - If new feature, suggest running `/sp.specify` in the worktree

### 3. Remove Worktree

When user wants to remove a worktree:

a. **List worktrees first** so user can confirm

b. **Get worktree path** from user or detect current

c. **Remove the worktree**:

```bash
# Source common functions first for worktree-aware operations
SCRIPT_DIR="$PWD"
if [ -f "scripts/bash/common.sh" ]; then
    source scripts/bash/common.sh
    REPO_ROOT="$(get_repo_root)"
elif [ -f "$SCRIPT_DIR/scripts/bash/common.sh" ]; then
    source "$SCRIPT_DIR/scripts/bash/common.sh"
    REPO_ROOT="$(get_repo_root)"
else
    # Fallback if common.sh not found
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

# Remove worktree
WORKTREE_PATH="/path/to/worktree"  # Use actual path
git worktree remove "$WORKTREE_PATH" || git worktree remove --force "$WORKTREE_PATH"

echo "✓ Worktree removed: $WORKTREE_PATH"
```

d. **Prune stale references**:

```bash
git worktree prune
echo "✓ Pruned stale worktree references"
```

### 4. Enable Worktree Mode

When user wants to enable worktree mode for all /sp.specify commands:

a. **Explain what will happen**:
   - All future `/sp.specify` commands will create worktrees instead of branches
   - User will work in separate directories for each feature
   - Main repo stays clean

b. **Set environment variable**:

```bash
export SPECIFY_WORKTREE_MODE=true
echo "✓ Worktree mode enabled for this session"
echo ""
echo "To make it permanent, add to your shell profile (~/.bashrc or ~/.zshrc):"
echo "  export SPECIFY_WORKTREE_MODE=true"
```

c. **Create worktrees directory**:

```bash
# Get repo root (worktree-aware)
if [ -f "scripts/bash/common.sh" ]; then
    source scripts/bash/common.sh
    REPO_ROOT="$(get_repo_root)"
else
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
mkdir -p "$REPO_ROOT/../worktrees"
echo "✓ Created worktrees directory: $REPO_ROOT/../worktrees"
```

### 5. Help/Info

When user wants help or general info:

Show this guidance:

```
Git Worktree Mode for SpecKit Plus
===================================

Git worktrees allow you to work on multiple features simultaneously in separate
directories, all sharing the same git history.

Directory Structure:
  my-project/              ← Main repository (stays on main branch)
  ├── specs/               ← Shared across all worktrees
  ├── history/             ← Shared across all worktrees
  └── templates/           ← Shared across all worktrees

  worktrees/               ← Sibling directory with worktrees
  ├── 001-auth/            ← Worktree for feature 001
  ├── 002-dashboard/       ← Worktree for feature 002
  └── 003-api/             ← Worktree for feature 003

Usage:
  /sp.worktree list              List all worktrees
  /sp.worktree create 001-auth   Create worktree for feature
  /sp.worktree remove <path>     Remove a worktree
  /sp.worktree enable            Enable worktree mode

Workflow:
  1. In main repo: /sp.worktree create 001-auth
  2. Switch to worktree: cd ../worktrees/001-auth
  3. Create spec: /sp.specify "Authentication system"
  4. Develop feature in worktree
  5. Commit and push from worktree
  6. When done: /sp.worktree remove ../worktrees/001-auth

Benefits:
  ✓ Work on multiple features without switching branches
  ✓ No stashing required
  ✓ Each feature has its own working directory
  ✓ Main repo stays clean
  ✓ All specs and history are shared

Note: specs/ and history/ are accessed from the main repo root automatically.
```

## Important Notes

1. **Always source common.sh** for helper functions
2. **Use absolute paths** for worktree operations
3. **Check git is available** before operations
4. **Provide clear feedback** at each step
5. **Handle errors gracefully** with helpful messages

## Error Handling

If any command fails:
- Show clear error message
- Suggest corrective action
- Don't leave system in inconsistent state

Common errors:
- Not in git repository → Suggest running from repo
- Worktree already exists → List existing worktrees
- Branch already exists → Offer to create worktree from existing branch
- Permission issues → Check directory permissions
