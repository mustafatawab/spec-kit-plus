# `/sp.worktree` - Git Worktree Management Command

## Overview

The `/sp.worktree` command manages git worktrees for parallel feature development. Work on multiple features simultaneously without branch switching, stashing, or context loss.

## What are Git Worktrees?

Git worktrees allow you to have multiple working directories from a single repository, each on a different branch. This enables true parallel development.

**Traditional workflow:**
```bash
# Working on Feature A
git checkout feature-a
vim src/feature-a.ts
# Need to switch to Feature B urgently
git stash
git checkout feature-b
# Work on B...
git checkout feature-a
git stash pop  # Conflicts? Context loss!
```

**Worktree workflow:**
```bash
# Terminal 1: Feature A
cd worktrees/001-feature-a
vim src/feature-a.ts
# Leave it running!

# Terminal 2: Feature B (independent!)
cd worktrees/002-feature-b
vim src/feature-b.ts
```

## Usage

### List Worktrees
```bash
/sp.worktree list
```

**Output:**
```
/path/to/main-repo                    (main)
/path/to/worktrees/001-user-auth      (001-user-auth)
/path/to/worktrees/002-task-crud      (002-task-crud)
```

### Create Worktree
```bash
/sp.worktree create "feature description"
```

**Example:**
```bash
/sp.worktree create "user authentication system"
```

**Output:**
```
✓ Worktree created: /path/to/worktrees/001-user-auth
Branch: 001-user-auth

To switch to this worktree:
  cd ../worktrees/001-user-auth
```

### Remove Worktree
```bash
/sp.worktree remove <path>
```

**Example:**
```bash
/sp.worktree remove ../worktrees/001-user-auth
```

Removes the worktree and deletes the branch if it's been merged.

### Enable Worktree Mode
```bash
/sp.worktree enable
```

Sets `SPECIFY_WORKTREE_MODE=true` so `/sp.specify` automatically creates worktrees instead of branches.

## Automatic Worktree Mode

### Enable Permanently
```bash
# Add to ~/.bashrc or ~/.zshrc
export SPECIFY_WORKTREE_MODE=true
```

### With Worktree Mode Enabled
```bash
/sp.specify "OAuth2 authentication"
# Automatically creates worktree instead of branch!
```

### Without Worktree Mode
```bash
# Manual worktree creation
/sp.worktree create "OAuth2 authentication"
cd ../worktrees/001-oauth2
/sp.specify "OAuth2 authentication"
```

## Directory Structure

When you create worktrees, your repository structure becomes:

```
my-project/              ← Main repo (stays on main)
├── specs/               ← Shared across all worktrees
│   ├── 001-feature-a/
│   ├── 002-feature-b/
│   └── 003-feature-c/
├── history/             ← Shared across all worktrees
│   ├── constitution.md
│   └── prompts/
└── .git/

worktrees/               ← Feature worktrees (created by command)
├── 001-feature-a/       ← Worktree on branch 001-feature-a
├── 002-feature-b/       ← Worktree on branch 002-feature-b
└── 003-feature-c/       ← Worktree on branch 003-feature-c
```

**Key Point:** `specs/` and `history/` are in the main repo and shared by all worktrees!

## Benefits

### 1. No Context Switching Overhead
Each worktree preserves its working state:
```bash
# Feature A: Uncommitted changes, tests running
cd worktrees/001-feature-a
npm test -- --watch  # Leave running

# Feature B: Different code, different tests
cd ../002-feature-b
npm test -- --watch  # Independent!
```

### 2. Parallel AI Sessions
Run separate AI agent sessions per worktree:
```bash
# Terminal 1
cd worktrees/001-auth
claude  # AI focused on auth

# Terminal 2
cd worktrees/002-tasks
claude  # AI focused on tasks
```

### 3. Main Branch Always Clean
```bash
cd main-repo
git status
# On branch main, nothing to commit ✅
```

### 4. Shared Specs and History
```bash
# In any worktree
cat ../../main-repo/specs/001-auth/spec.md  # Accessible!
cat ../../main-repo/history/constitution.md # Shared!
```

## Multi-Session Workflow

### Step 1: Enable Worktree Mode
```bash
export SPECIFY_WORKTREE_MODE=true
echo 'export SPECIFY_WORKTREE_MODE=true' >> ~/.bashrc
```

### Step 2: Create Features
```bash
# Main repo
/sp.worktree create "user authentication"
/sp.worktree create "task CRUD operations"
/sp.worktree create "task collaboration"
```

### Step 3: Develop in Parallel
```bash
# Terminal 1: Feature 1
cd worktrees/001-user-auth
/sp.specify "JWT authentication with refresh tokens"
/sp.plan
/sp.implement

# Terminal 2: Feature 2 (simultaneously!)
cd worktrees/002-task-crud
/sp.specify "Task CRUD operations"
/sp.plan
/sp.implement

# Terminal 3: Feature 3
cd worktrees/003-collaborate
/sp.specify "Task assignment and collaboration"
/sp.plan
/sp.implement
```

### Step 4: Complete Features Independently
```bash
# Feature 1 complete
cd worktrees/001-user-auth
git commit -am "feat: Complete authentication"
git push origin 001-user-auth
gh pr create

# Remove completed worktree
cd ../../main-repo
/sp.worktree remove ../worktrees/001-user-auth

# Features 2 and 3 continue unaffected!
```

## Best Practices

### 1. Keep 2-3 Worktrees Max
```bash
# Good
worktrees/
├── 001-critical-feature/
├── 002-experimental/
└── 003-bugfix/

# Too many (hard to track)
worktrees/
├── 001-feature/
├── 002-feature/
├── 003-feature/
├── 004-feature/
├── 005-feature/  # ❌ Overwhelming
```

### 2. Name Worktrees Descriptively
```bash
# Good
/sp.worktree create "OAuth2 authentication system"
# → worktrees/001-oauth2-auth

# Less helpful
/sp.worktree create "feature"
# → worktrees/001-feature
```

### 3. Clean Up Merged Worktrees
```bash
# After PR merged
/sp.worktree remove ../worktrees/001-feature
git branch -d 001-feature
```

### 4. Share Specs Early
```bash
# In worktree
cd worktrees/001-feature
/sp.specify "Your feature"
# Spec created in main-repo/specs/001-feature/

# Commit spec for team visibility
git add ../../main-repo/specs/001-feature/
git commit -m "spec: Add feature specification"
git push origin 001-feature
```

## Advanced Patterns

### Hot-Swapping Features
```bash
# Define aliases in ~/.bashrc
alias wt1='cd /path/to/worktrees/001-user-auth'
alias wt2='cd /path/to/worktrees/002-task-crud'
alias wtmain='cd /path/to/main-repo'

# Quick switching
wt1  # Jump to Feature 1
wt2  # Jump to Feature 2
```

### Parallel Testing
```bash
# Terminal 1
cd worktrees/001-feature
npm test -- --watch

# Terminal 2
cd worktrees/002-feature
npm test -- --watch

# All tests run simultaneously!
```

### Hotfix During Feature Development
```bash
# Working on feature
cd worktrees/001-feature
# Uncommitted changes

# Urgent production bug!
cd ../../main-repo
/sp.worktree create "hotfix payment crash"
cd ../worktrees/hotfix-payment-crash

# Fix bug from clean main branch
vim src/payments/stripe.ts
git commit -am "fix: Handle null customer ID"
git push origin hotfix-payment-crash

# Back to feature work
cd ../001-feature
# ✅ All your work still here!
```

## Integration with SpecKit Plus Workflow

Worktrees integrate seamlessly with all commands:

```bash
cd worktrees/001-feature

# All commands work normally
/sp.specify "Feature description"
/sp.plan
/sp.tasks
/sp.implement
/sp.review
/sp.git.commit_pr

# Specs created in main-repo/specs/001-feature/ ✅
# History created in main-repo/history/ ✅
```

## Worktree Commands Reference

| Command | Action |
|---------|--------|
| `/sp.worktree list` | Show all worktrees |
| `/sp.worktree create "desc"` | Create new worktree |
| `/sp.worktree remove <path>` | Remove worktree |
| `/sp.worktree enable` | Enable automatic worktree mode |

## Troubleshooting

### "Not a git repository"
Worktrees require git:
```bash
git init
git add .
git commit -m "Initial commit"
# Now worktrees work
```

### "Cannot create worktree on same branch"
Each worktree must be on a different branch:
```bash
# ❌ Error: Branch already has worktree
/sp.worktree create "feature"  # Creates 001-feature
/sp.worktree create "feature"  # Error! 001-feature already exists

# ✅ Use different descriptions
/sp.worktree create "feature A"
/sp.worktree create "feature B"
```

### "Specs not shared across worktrees"
Verify you're using worktree-aware functions:
```bash
cd worktrees/001-feature
source ../../main-repo/scripts/bash/common.sh
get_repo_root
# Should output: /path/to/main-repo (not worktree path!)
```

### "Too many worktrees, confused"
Use `list` to see all worktrees:
```bash
/sp.worktree list
```

Remove unneeded ones:
```bash
/sp.worktree remove ../worktrees/old-feature
```

## Tutorials

For detailed tutorials, see:

- [Multi-Session Workflow Tutorial](../../04_git_worktrees/01_multi_session_workflow.md) - Learn parallel development with 3 features
- [Advanced Worktree Patterns](../../04_git_worktrees/02_advanced_patterns.md) - Team coordination, CI/CD, hotfixes

## Related Commands

- [`/sp.specify`](../03_spec/readme.md) - Create specification (can auto-create worktree)
- [`/sp.review`](../10_review/readme.md) - Review implementation
- [`/sp.git.commit_pr`](../09_git_commit_pr/readme.md) - Create PR from worktree

## When to Use Worktrees

**Use worktrees when:**
- ✅ Working on 2-3 features simultaneously
- ✅ Need to switch features frequently (hotfixes)
- ✅ Running multiple AI sessions
- ✅ Testing different approaches in parallel
- ✅ Team wants shared specs/history

**Stick with branches when:**
- ❌ Working on single feature at a time
- ❌ Learning git basics
- ❌ Project doesn't use git
- ❌ Very short tasks (< 30 min)

## Summary

The `/sp.worktree` command provides:
- ✅ True parallel development (no stashing)
- ✅ Context preservation per feature
- ✅ Shared specs and history
- ✅ Clean main branch always
- ✅ Multi-session AI support
- ✅ Hotfix-friendly workflow

Use it when you need to juggle multiple features and want instant context switching!
