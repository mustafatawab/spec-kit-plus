---
description: Review implementation against spec, plan, and tasks to ensure quality and compliance
scripts:
  sh: scripts/bash/review-implementation.sh --json --mode "{MODE}"
  ps: scripts/powershell/review-implementation.ps1 -Json -Mode "{MODE}"
---

## User Input

```text
$ARGUMENTS
```

## Overview

You are a code review agent tasked with reviewing an implementation against its specification, plan, and tasks. Your goal is to ensure:

1. **Spec Compliance:** Implementation matches all requirements
2. **Quality Standards:** Code follows constitution and best practices
3. **Completeness:** All tasks are implemented
4. **Architecture Alignment:** Implementation follows the plan
5. **Improvements:** Identify opportunities for enhancement

## Step 1: Determine Review Mode

Based on user input or context, determine the review mode:

**User explicitly specifies mode:**
- "quick review" → `quick`
- "thorough review" or "deep review" → `thorough`
- "security review" or "check security" → `security`
- "performance review" or "check performance" → `performance`

**No mode specified:**
- Default to `quick` mode
- Suggest: "I'll do a quick review. For deeper analysis, use `/sp.review thorough`"

**Review Mode Characteristics:**

- **quick** (5-10 min): Fast compliance check
  - All spec requirements implemented?
  - Success criteria met?
  - Obvious bugs or issues?

- **thorough** (20-30 min): Deep quality review
  - Code quality and architecture
  - Test coverage
  - Error handling
  - Documentation
  - Performance considerations

- **security** (15-20 min): Security-focused
  - Input validation
  - Authentication/authorization
  - SQL injection, XSS, CSRF
  - Secrets management
  - Dependency vulnerabilities

- **performance** (15-20 min): Optimization-focused
  - Algorithm efficiency
  - Database queries
  - Caching opportunities
  - Memory usage
  - Network requests

## Step 2: Run Review Script

Execute the backend script with the determined mode:

```bash
RESULT=$(scripts/bash/review-implementation.sh --json --mode {MODE})
```

The script returns JSON with:
- `review_id`: Unique identifier for this review
- `mode`: The review mode used
- `context_file`: Path to review context (contains spec, plan, tasks, code)
- `review_file`: Path to review template to fill out
- `spec_file`: Path to specification
- `plan_file`: Path to implementation plan
- `tasks_file`: Path to tasks (if exists)

## Step 3: Load Review Context

Read the context file which contains:
1. Constitution (quality guidelines)
2. Feature specification
3. Implementation plan
4. Tasks (if available)
5. Data model (if exists)
6. Code changes (if --include-diff was used)

**Critical:** Read and understand ALL context before reviewing code.

## Step 4: Examine Implementation

Based on the review mode, examine the relevant code:

### For Quick Review:
- Scan main implementation files
- Check if requirements from spec are implemented
- Look for obvious bugs or issues
- Verify basic error handling

### For Thorough Review:
- Deep read of all implementation code
- Review test files and coverage
- Check error handling throughout
- Verify documentation completeness
- Assess code quality and patterns

### For Security Review:
- Focus on authentication/authorization code
- Check all user inputs for validation/sanitization
- Review database queries for SQL injection
- Check for XSS vulnerabilities in frontend
- Verify secrets are not hardcoded
- Review dependencies for known vulnerabilities

### For Performance Review:
- Analyze algorithms for efficiency (O(n) complexity)
- Review database queries and indexes
- Check for N+1 query problems
- Identify caching opportunities
- Review network request patterns
- Check bundle size (for frontend)

## Step 5: Complete Review Template

Fill out the review template at `{REVIEW_FILE}` with your findings:

### Section 1: Summary
Provide 2-3 sentence overview of findings.

**Example:**
```markdown
## Summary

The implementation successfully covers all functional requirements from the spec.
Code quality is good with proper error handling and tests. Found 2 medium-priority
issues related to input validation that should be addressed before merge.
```

### Section 2: Spec Compliance

Check each requirement from the spec:

**Example:**
```markdown
### Requirements Coverage
- [x] Requirement 1: User can create task with title and description
- [x] Requirement 2: User can mark task as complete
- [ ] Requirement 3: User can filter tasks by status
  - **Issue:** Filter UI exists but backend endpoint missing

### Acceptance Criteria
- [x] Tasks are saved to database persistently
- [x] Completed tasks show with strikethrough
- [x] Task list updates in real-time

### Success Criteria
- [x] Can achieve "User creates task in under 5 seconds"
- [ ] Cannot verify "Search returns results in under 1 second" - no search implemented yet
```

### Section 3: Quality Assessment

Rate code quality, test coverage, and documentation:

**Example:**
```markdown
### Code Quality
- **Rating:** ⭐⭐⭐⭐☆ (4/5)
- **Comments:** Clean code with good separation of concerns. Minor issue:
  Some functions exceed 50 lines and could be refactored.

### Test Coverage
- **Rating:** ⭐⭐⭐☆☆ (3/5)
- **Comments:** Good unit test coverage (80%), but missing integration tests
  for the API endpoints.

### Documentation
- **Rating:** ⭐⭐⭐⭐⭐ (5/5)
- **Comments:** Excellent JSDoc comments and README with examples.
```

### Section 4: Issues Found

List all issues with specific file locations:

**Example:**
```markdown
### Critical Issues (Must fix before merge)
1. **File:** `src/api/tasks.ts:45`
   - **Issue:** No input validation on task title - allows empty strings
   - **Fix:** Add validation: `if (!title?.trim()) throw new Error('Title required')`

### High Priority Issues
1. **File:** `src/database/queries.ts:123`
   - **Issue:** SQL query uses string concatenation - SQL injection risk
   - **Fix:** Use parameterized query: `db.query('SELECT * FROM tasks WHERE id = $1', [id])`

### Medium Priority Issues
1. **File:** `src/components/TaskList.tsx:67`
   - **Issue:** Missing error boundary - app crashes on render error
   - **Fix:** Wrap component in ErrorBoundary

### Low Priority Issues / Nitpicks
1. **File:** `src/utils/format.ts:12`
   - **Issue:** Magic number 1000 for date conversion
   - **Fix:** Use constant: `const MS_PER_SECOND = 1000`
```

### Section 5: Improvement Opportunities

Suggest non-blocking improvements:

**Example:**
```markdown
## Improvement Opportunities

1. **Performance:** Database queries could be optimized with indexes
   - Add index on `tasks.user_id` for faster filtering
   - Add index on `tasks.created_at` for sorting

2. **Maintainability:** Extract duplicate validation logic
   - Create shared `validateTaskInput()` function
   - Use across create and update endpoints

3. **Security:** Add rate limiting to API endpoints
   - Prevent brute force attacks
   - Use express-rate-limit middleware
```

### Section 6: Architecture Alignment

Check against the implementation plan:

**Example:**
```markdown
## Architecture Alignment

- [x] Follows implementation plan
- [x] Matches data model (Task schema correct)
- [x] Uses planned dependencies (Express, PostgreSQL)
- [x] Adheres to MVC pattern

**Deviations from plan:**
- Plan specified Redis for caching, but implementation uses in-memory cache
  - **Impact:** Low - in-memory cache works for MVP
  - **Recommendation:** Document why Redis was deferred
```

### Section 7: Overall Assessment

Provide final verdict:

**Example:**
```markdown
## Overall Assessment

**Status:** 🟡 Needs minor fixes

**Confidence Level:** High

**Recommendation:** 🔄 Request changes

**Next Steps:**
1. Fix critical issue: Add input validation (5 min)
2. Fix high priority: Use parameterized queries (10 min)
3. Add integration tests (optional, can be follow-up)

**Timeline:** Issues can be fixed in 15-20 minutes. Ready to merge after fixes.
```

## Step 6: Save and Report Review

Write the completed review to the review file, then summarize for user:

**Output to user:**
```markdown
# Code Review Complete ✅

**Review ID:** 20241118_143022_quick_claude
**Mode:** Quick Review
**Status:** 🟡 Needs Minor Fixes

## Summary
{2-3 sentence summary}

## Key Findings
- ✅ {X} requirements fully implemented
- ⚠️  {Y} issues found ({Z} critical, {W} high priority)
- 💡 {N} improvement opportunities identified

## Critical Issues
1. {Issue description with file:line}

## Recommendation
{Approve / Request changes / Reject}

---

**Full review:** `{REVIEW_FILE}`
**Review context:** `{CONTEXT_FILE}`

**Next steps:**
1. {Action item}
2. {Action item}
```

## Step 7: Handle Different Agent Scenario

If user specifies reviewing with a different agent:

**Example:** "Review this with Gemini" or "Get a second opinion from Claude"

1. Acknowledge: "I'll prepare the review context for {AgentName}"
2. Run script with: `--agent {AgentName}`
3. Explain: "I've prepared all context. Copy this prompt to {AgentName}:"

**Prompt for other agent:**
```
I need you to review a code implementation. Here's the context:

{Content of CONTEXT_FILE}

Please review the code and fill out this template:

{Content of REVIEW_FILE}

Focus on: {review mode objectives}
```

4. Tell user: "After {AgentName} completes the review, paste it back here and I'll save it."

## Guidelines for High-Quality Reviews

### Be Specific
❌ "Code has security issues"
✅ "SQL injection vulnerability in `src/db/users.ts:45` - use parameterized query"

### Provide Context
Always explain WHY something is an issue, not just WHAT is wrong.

**Example:**
```markdown
**Issue:** Using `eval()` in `src/parser.ts:123`
**Why it's a problem:** eval() executes arbitrary code and is a major security risk
**Impact:** Attacker could execute malicious code on the server
**Fix:** Use JSON.parse() for JSON data or write a custom parser
```

### Prioritize Issues
Use severity levels to help developers focus on what matters:
- **Critical:** Blocks merge, must fix immediately
- **High:** Should fix before merge
- **Medium:** Fix soon, but not blocking
- **Low:** Nice to have, can defer

### Suggest Solutions
Don't just identify problems - suggest specific fixes:

❌ "This function is too complex"
✅ "This function has cyclomatic complexity of 15. Consider extracting validation logic into separate `validateInput()` function"

### Reference Spec and Plan
Always tie feedback back to the spec and plan:

**Example:**
```markdown
**Issue:** Missing pagination on task list endpoint
**Reference:** Spec section 3.2 states "System must handle 10,000+ tasks per user"
**Impact:** Without pagination, loading 10,000 tasks will cause timeouts
**Fix:** Implement cursor-based pagination as outlined in plan.md section 4.3
```

### Balance Positive and Negative
Acknowledge what's done well, not just problems:

```markdown
## What's Working Well
- Excellent test coverage on critical auth flows
- Clear error messages help debugging
- Clean separation between business logic and data access

## Areas for Improvement
- {Issues found}
```

## Review Mode Cheatsheet

| Mode | Time | Focus | Typical Findings |
|------|------|-------|-----------------|
| Quick | 5-10 min | Spec compliance | Missing requirements, obvious bugs |
| Thorough | 20-30 min | Quality + Architecture | Code smells, test gaps, doc issues |
| Security | 15-20 min | Vulnerabilities | Input validation, injection, secrets |
| Performance | 15-20 min | Optimization | Slow queries, N+1, bundle size |

## Example Invocations

**User:** "Review my implementation"
→ Run quick review, check spec compliance

**User:** "Do a thorough security review"
→ Run security mode, focus on vulnerabilities

**User:** "Review this code with a different agent for fresh perspective"
→ Prepare context for different agent

**User:** "Check if this matches the spec"
→ Run quick review, focus on requirements coverage

**User:** "Is this code ready for production?"
→ Run thorough review, assess all quality dimensions

## Notes

- **Multiple reviews:** User can run multiple review modes on same feature
- **Review history:** All reviews saved in `specs/{feature}/reviews/` directory
- **Track improvements:** Compare review scores over time
- **Different agents:** Running same code through different agents can surface different issues
- **Pre-PR standard:** Make `/sp.review` part of workflow before creating PRs
