#!/usr/bin/env bash
# Run all review command tests (bash + PowerShell)

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SpecKit Plus Review Command - All Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

BASH_PASSED=false
PWSH_PASSED=false

# Run bash tests
echo -e "${YELLOW}Running Bash Tests...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if bash "$SCRIPT_DIR/test-review.sh"; then
    echo -e "${GREEN}✓ Bash tests passed${NC}"
    BASH_PASSED=true
else
    echo -e "${RED}✗ Bash tests failed${NC}"
fi

echo ""
echo ""

# Run PowerShell tests if available
if command -v pwsh >/dev/null 2>&1; then
    echo -e "${YELLOW}Running PowerShell Tests...${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if pwsh "$SCRIPT_DIR/test-review.ps1"; then
        echo -e "${GREEN}✓ PowerShell tests passed${NC}"
        PWSH_PASSED=true
    else
        echo -e "${RED}✗ PowerShell tests failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠ PowerShell not available, skipping PowerShell tests${NC}"
    PWSH_PASSED=true  # Don't fail if PowerShell isn't available
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Overall Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if $BASH_PASSED; then
    echo -e "${GREEN}✓${NC} Bash tests:       PASSED"
else
    echo -e "${RED}✗${NC} Bash tests:       FAILED"
fi

if command -v pwsh >/dev/null 2>&1; then
    if $PWSH_PASSED; then
        echo -e "${GREEN}✓${NC} PowerShell tests: PASSED"
    else
        echo -e "${RED}✗${NC} PowerShell tests: FAILED"
    fi
else
    echo -e "${YELLOW}⚠${NC} PowerShell tests: SKIPPED (not installed)"
fi

echo ""

if $BASH_PASSED && $PWSH_PASSED; then
    echo -e "${GREEN}✓ All review tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some review tests failed${NC}"
    exit 1
fi
