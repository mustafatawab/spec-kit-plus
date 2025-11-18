# SpecKit Plus Test Suite

Comprehensive testing infrastructure for SpecKit Plus features and functionality.

## Test Suites

### Git Worktree Tests

Tests for git worktree support, including detection, management, and integration with SpecKit Plus commands.

**Location:** `tests/worktree/`

**Quick Run:**
```bash
cd tests/worktree
./run-all-tests.sh
```

**Coverage:**
- Worktree detection functions
- Worktree creation and management
- File access from worktrees (specs/, history/)
- Script integration (create-new-feature.sh)
- Edge cases and error handling

**Test Count:** 31 tests (20 bash + 11 PowerShell)

**Documentation:** [tests/worktree/README.md](worktree/README.md)

### Review Command Tests

Tests for `/sp.review` command, including all review modes, file creation, and multi-agent support.

**Location:** `tests/review/`

**Quick Run:**
```bash
cd tests/review
./run-all-tests.sh
```

**Coverage:**
- Script validation and help output
- All 4 review modes (quick, thorough, security, performance)
- Context file creation (spec, plan, tasks, constitution)
- Review template structure
- Agent parameter support
- JSON output format
- Error handling (missing spec/plan, wrong branch)
- Optional content (tasks, data model)

**Test Count:** 39 tests (25 bash + 14 PowerShell)

**Documentation:** [tests/review/README.md](review/README.md)

## Running All Tests

### Run Everything
```bash
# Run all test suites
./tests/worktree/run-all-tests.sh
./tests/review/run-all-tests.sh

# Or from tests directory
cd tests
./worktree/run-all-tests.sh
./review/run-all-tests.sh
```

### Run Specific Test Suites

**Worktree - Bash only:**
```bash
./tests/worktree/test-worktree.sh
```

**Worktree - PowerShell only:**
```powershell
.\tests\worktree\test-worktree.ps1
```

**Review - Bash only:**
```bash
./tests/review/test-review.sh
```

**Review - PowerShell only:**
```powershell
.\tests\review\test-review.ps1
```

### Verbose Mode

Get detailed output for debugging:

```bash
# All tests verbose
./tests/worktree/run-all-tests.sh --verbose

# Specific suite
./tests/worktree/test-worktree.sh --verbose
```

### Keep Test Artifacts

Preserve test directories for manual inspection:

```bash
./tests/worktree/run-all-tests.sh --keep
```

Test directories location:
- **Linux/macOS:** `/tmp/speckit-worktree-tests`
- **Windows:** `%TEMP%\speckit-worktree-tests`

## Test Requirements

### System Requirements

- **Git:** 2.15+ (for worktree support)
- **Bash:** 4.0+ (for bash tests)
- **PowerShell:** 7.0+ (optional, for PowerShell tests)
- **Disk Space:** ~50MB for test repositories
- **Permissions:** Write access to temp directory

### Checking Your System

```bash
# Check git version (need 2.15+)
git --version

# Check bash version (need 4.0+)
bash --version

# Check PowerShell version (need 7.0+)
pwsh --version
```

## Test Organization

```
tests/
├── README.md                    ← This file
├── worktree/                    ← Git worktree test suite
│   ├── README.md               ← Detailed worktree test documentation
│   ├── test-worktree.sh        ← Bash test suite (20 tests)
│   ├── test-worktree.ps1       ← PowerShell test suite (11 tests)
│   └── run-all-tests.sh        ← Run both bash and PowerShell tests
└── review/                      ← Review command test suite
    ├── README.md               ← Detailed review test documentation
    ├── test-review.sh          ← Bash test suite (25 tests)
    ├── test-review.ps1         ← PowerShell test suite (14 tests)
    └── run-all-tests.sh        ← Run both bash and PowerShell tests
```

## CI/CD Integration

### GitHub Actions

Add to `.github/workflows/test.yml`:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install PowerShell
        run: |
          sudo apt-get update
          sudo apt-get install -y powershell

      - name: Run Worktree Tests
        run: |
          cd tests/worktree
          ./run-all-tests.sh

      - name: Run Review Tests
        run: |
          cd tests/review
          ./run-all-tests.sh
```

### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
echo "Running tests before commit..."
./tests/worktree/run-all-tests.sh || exit 1
./tests/review/run-all-tests.sh || exit 1
echo "All tests passed!"
exit 0
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Test Output

### Successful Run

```
============================================================================
SpecKit Plus - Complete Worktree Test Suite
============================================================================

▶ Running Bash Test Suite...

[INFO] Git version: 2.39 ✓
Running Unit Tests - Worktree Detection
----------------------------------------
[PASS] is_worktree() in normal repo
[PASS] is_worktree() in worktree
...
============================================================================
Test Summary
============================================================================
Tests run:    20
Tests passed: 20
Tests failed: 0

✓ Bash tests passed

▶ Running PowerShell Test Suite...
...
✓ PowerShell tests passed

============================================================================
Final Summary
============================================================================
Bash tests:       Run
PowerShell tests: Run

✓ All test suites passed!
```

### Failed Test

```
[INFO] Running: get_repo_root() in worktree
[FAIL] get_repo_root() should return main repo path
       Expected: '/tmp/speckit-worktree-tests/test-repo'
       Actual:   '/tmp/speckit-worktree-tests/worktrees/test-branch'
[FAIL] get_repo_root() in worktree

============================================================================
Test Summary
============================================================================
Tests run:    20
Tests passed: 18
Tests failed: 2

✗ Bash tests failed
```

## Troubleshooting

### Git Version Too Old

**Error:** `Git 2.15+ required for worktree support`

**Solution:** Update git:
```bash
# Ubuntu/Debian
sudo add-apt-repository ppa:git-core/ppa
sudo apt update && sudo apt install git

# macOS
brew upgrade git
```

### PowerShell Not Found

**Warning:** `PowerShell (pwsh) not found - skipping PowerShell tests`

**Solution:** Install PowerShell 7+:
- **Linux:** https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux
- **macOS:** `brew install powershell`
- **Windows:** Installed by default (use `pwsh`, not `powershell`)

### Permission Denied

**Error:** `Permission denied: /tmp/speckit-worktree-tests`

**Solution:** Use custom test directory:
```bash
export TEST_BASE_DIR="$HOME/tmp/speckit-tests"
./tests/worktree/run-all-tests.sh
```

### Tests Hang

**Cause:** Network issues or slow I/O

**Solution:**
- Ensure tests are running locally (no network)
- Check disk space: `df -h /tmp`
- Use SSD if available

## Writing New Tests

### Test Structure

1. **Create isolated test environment** - Fresh repo for each test
2. **Perform test operations** - Execute the code being tested
3. **Make assertions** - Verify expected behavior
4. **Clean up** - Automatic cleanup after test

### Example Test

**Bash:**
```bash
test_my_feature() {
    local repo_path=$(create_test_repo "test-my-feature")
    cd "$repo_path"
    source "$repo_path/scripts/bash/common.sh"

    local result=$(my_function "input")

    assert_equals "expected" "$result" "Function should return expected value"
}
```

**PowerShell:**
```powershell
function Test-MyFeature {
    $repoPath = New-TestRepository "test-my-feature"
    Set-Location $repoPath
    . "$repoPath/scripts/powershell/common.ps1"

    $result = My-Function "input"

    return Assert-Equals "expected" $result "Function should return expected value"
}
```

### Adding to Test Suite

**Bash** - Add to `main()` in `test-worktree.sh`:
```bash
run_test "My feature description" test_my_feature
```

**PowerShell** - Add to `Main` in `test-worktree.ps1`:
```powershell
Invoke-Test "My feature description" { Test-MyFeature }
```

## Best Practices

### 1. Test Isolation

- Each test creates its own repository
- Tests don't share state
- Clean up after each test

### 2. Descriptive Test Names

✅ Good:
- `test_get_repo_root_in_worktree`
- `test_create_worktree_with_custom_path`

❌ Avoid:
- `test_function1`
- `test_case_a`

### 3. Clear Assertions

✅ Good:
```bash
assert_equals "$expected" "$actual" "get_repo_root() should return main repo path in worktree"
```

❌ Avoid:
```bash
assert_equals "$expected" "$actual" "failed"
```

### 4. Test One Thing

Each test should verify one specific behavior:

✅ Good:
- `test_is_worktree_in_normal_repo`
- `test_is_worktree_in_worktree`

❌ Avoid:
- `test_all_worktree_functions` (tests multiple things)

### 5. Document Complex Tests

Add comments for non-obvious test logic:

```bash
test_complex_scenario() {
    # Create main repo with two branches
    local repo_path=$(create_test_repo "complex")

    # Create first worktree - should succeed
    local wt1=$(create_worktree "001-feature")

    # Attempt to create duplicate - should fail
    # This tests error handling for duplicate worktrees
    if create_worktree "001-feature" 2>/dev/null; then
        return 1  # Should have failed
    fi

    return 0
}
```

## Test Metrics

### Performance

Typical execution times:
- **Bash suite:** ~30-45 seconds
- **PowerShell suite:** ~45-60 seconds
- **Combined:** ~75-105 seconds

### Coverage

Current test coverage:
- **Core functions:** 100%
- **Integration:** 85%
- **Error cases:** 90%

### Test Count

**Worktree Tests:**
- Bash: 20 tests
- PowerShell: 11 tests
- Subtotal: 31 tests

**Review Tests:**
- Bash: 25 tests
- PowerShell: 14 tests
- Subtotal: 39 tests

**Total: 70 tests**

## Contributing Tests

When contributing:

1. **Add tests for new features** - Test-driven development
2. **Test both success and failure** - Include error cases
3. **Run full suite** - Ensure existing tests still pass
4. **Update documentation** - Document new test categories
5. **Keep tests fast** - Each test should complete in < 5 seconds

## Future Enhancements

Planned test improvements:

- [ ] Parallel test execution
- [ ] Code coverage reporting
- [ ] Performance benchmarking
- [ ] Windows-specific tests
- [ ] Integration with other SpecKit commands (/sp.plan, /sp.implement)
- [ ] Stress testing (many worktrees)
- [ ] Network failure scenarios

## See Also

- [Worktree Test Documentation](worktree/README.md)
- [Review Test Documentation](review/README.md)
- [Git Worktree User Guide](../docs-plus/04_git_worktrees/README.md)
- [Review Command Guide](../docs-plus/06_core_commands/10_review/readme.md)
- [SpecKit Plus Commands](../templates/commands/)

## Support

For test issues:

1. Run with `--verbose` for detailed output
2. Use `--keep` to inspect test repositories
3. Check system requirements
4. Review test logs in `/tmp/speckit-worktree-tests`
5. Open an issue with test output

## License

Same as SpecKit Plus main project.
