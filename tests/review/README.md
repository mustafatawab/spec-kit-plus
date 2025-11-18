# Review Command Tests

Comprehensive test suite for the `/sp.review` command functionality.

## Test Coverage

### Bash Tests (`test-review.sh`)
**25 tests** covering:

1. **Script Validation (3 tests)**
   - Review script exists
   - Review script is executable
   - Review script shows help

2. **Mode Detection (4 tests)**
   - Quick mode
   - Thorough mode
   - Security mode
   - Performance mode

3. **File Creation (5 tests)**
   - Creates context file
   - Creates review file
   - Context includes spec
   - Context includes plan
   - Context includes constitution

4. **Agent Parameter (2 tests)**
   - Custom agent parameter
   - Default agent (current user)

5. **JSON Output (1 test)**
   - Valid JSON output format

6. **Error Handling (3 tests)**
   - Errors when spec missing
   - Errors when plan missing
   - Errors when not on feature branch

7. **Tasks Integration (2 tests)**
   - Includes tasks if exists
   - Skips tasks if missing

8. **Data Model Integration (1 test)**
   - Includes data model if exists

9. **Review Template (2 tests)**
   - Template has correct structure
   - Template has checklist items

### PowerShell Tests (`test-review.ps1`)
**14 tests** covering:

1. **Script Validation (2 tests)**
   - Script exists
   - Shows help output

2. **Mode Detection (4 tests)**
   - All 4 review modes

3. **File Creation (4 tests)**
   - Context and review file creation
   - Content verification

4. **JSON Output (1 test)**
   - Valid JSON format

5. **Error Handling (2 tests)**
   - Missing spec/plan validation

## Running Tests

### Run All Tests (Recommended)
```bash
./run-all-tests.sh
```

Runs both Bash and PowerShell tests (if PowerShell is available).

### Run Bash Tests Only
```bash
./test-review.sh
```

### Run PowerShell Tests Only
```powershell
pwsh ./test-review.ps1
```

## Test Environment

Each test:
1. Creates a temporary git repository
2. Sets up required files (spec, plan, constitution)
3. Runs the review command
4. Validates output and created files
5. Cleans up temporary directory

## Expected Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SpecKit Plus Review Command Test Suite
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Repository: /path/to/spec-kit-plus
Review Script: /path/to/scripts/bash/review-implementation.sh

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Unit Tests - Script Validation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Running: Review script exists
✓ PASSED: Review script exists

Running: Review script is executable
✓ PASSED: Review script is executable

Running: Review script shows help
✓ PASSED: Review script shows help

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Test Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Tests Run:    25
Tests Passed: 25
Tests Failed: 0

✓ All tests passed!
```

## Test Categories Explained

### Script Validation
Ensures the review script exists, is executable, and provides help.

### Mode Detection
Verifies all 4 review modes work correctly:
- **quick**: Fast compliance check (5-10 min)
- **thorough**: Deep quality review (20-30 min)
- **security**: Security vulnerability scan (15-20 min)
- **performance**: Performance optimization review (15-20 min)

### File Creation
Validates that review creates required files:
- Context file (`*_context.md`) with spec, plan, tasks, constitution
- Review template (`*_review.md`) with checklist structure

### Agent Parameter
Tests multi-agent review support:
- Custom agent names in file paths
- Default agent (current user)

### JSON Output
Validates `--json` flag produces valid JSON with required fields.

### Error Handling
Ensures proper error messages when:
- Spec file missing
- Plan file missing
- Not on feature branch

### Optional Content
Tests conditional inclusion of:
- Tasks (if tasks.md exists)
- Data model (if data-model.md exists)

### Template Structure
Verifies review template has correct sections:
- Summary
- Spec Compliance
- Quality Assessment
- Issues Found
- Architecture Alignment
- Overall Assessment

## Adding New Tests

To add a new test:

1. **Add test function** in `test-review.sh` or `test-review.ps1`
2. **Use naming convention**: `test_review_<feature>`
3. **Call from main**: `run_test "Description" test_review_<feature>`
4. **Update this README** with test description

Example:
```bash
test_review_new_feature() {
    # Setup
    TEST_DIR=$(setup_test_env)

    # Execute
    # ... test code ...

    # Assert
    assert_equals "expected" "actual" "Should do X"

    # Cleanup
    cleanup_test_env
}
```

## Continuous Integration

These tests can be integrated into CI/CD:

**.github/workflows/test.yml:**
```yaml
- name: Run review command tests
  run: |
    cd tests/review
    ./run-all-tests.sh
```

## Troubleshooting

### Tests Timeout
Some tests create temporary git repos which can be slow. Increase timeout or run tests in smaller batches.

### Permission Errors
Ensure test scripts are executable:
```bash
chmod +x test-review.sh run-all-tests.sh
```

### PowerShell Not Found
PowerShell tests require PowerShell Core 6+. Install from:
- https://github.com/PowerShell/PowerShell

Or skip PowerShell tests and run bash only:
```bash
./test-review.sh
```

## Related Test Suites

- [Worktree Tests](../worktree/README.md) - Git worktree functionality
- [Main Tests](../README.md) - All SpecKit Plus tests

## Summary

The review command test suite provides comprehensive coverage of:
- ✅ 25 bash tests
- ✅ 14 PowerShell tests
- ✅ All 4 review modes
- ✅ File creation and content validation
- ✅ Error handling
- ✅ JSON output
- ✅ Multi-agent support

Run `./run-all-tests.sh` to validate the review command implementation!
