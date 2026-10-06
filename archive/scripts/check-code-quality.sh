#!/bin/bash

# Code quality guardrails check
# Checks for: hardcoded secrets, HTTP_STATUS usage, file size, import aliases, TODOs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() { echo -e "${RED}x $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}! $1${NC}"; }
print_info() { echo "i $1"; }

# Track errors and warnings
ERRORS=0
WARNINGS=0

# Determine which files to check
if [ "$1" == "--staged" ]; then
    FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '^src/.*\.(ts|tsx)$' || true)
else
    FILES=$(find src -name "*.ts" -o -name "*.tsx" 2>/dev/null | grep -v node_modules || true)
fi

if [ -z "$FILES" ]; then
    print_info "No files to check"
    exit 0
fi

echo "Running code quality checks..."
echo ""

# =============================================================================
# Check 1: Hardcoded secrets detection (BLOCKS commit)
# =============================================================================
echo "Checking for hardcoded secrets..."

SECRET_PATTERNS=(
    # API keys and tokens
    'api[_-]?key\s*[:=]\s*["\x27][a-zA-Z0-9_-]{20,}["\x27]'
    'api[_-]?secret\s*[:=]\s*["\x27][a-zA-Z0-9_-]{20,}["\x27]'
    'auth[_-]?token\s*[:=]\s*["\x27][a-zA-Z0-9_-]{20,}["\x27]'
    'bearer\s+[a-zA-Z0-9_-]{20,}'
    # AWS patterns
    'AKIA[0-9A-Z]{16}'
    'aws[_-]?secret[_-]?access[_-]?key\s*[:=]'
    # Database connection strings with credentials
    'mongodb(\+srv)?://[^:]+:[^@]+@'
    'postgres(ql)?://[^:]+:[^@]+@'
    'mysql://[^:]+:[^@]+@'
    # Private keys
    '-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----'
    # JWT secrets (hardcoded)
    'jwt[_-]?secret\s*[:=]\s*["\x27][a-zA-Z0-9_-]{16,}["\x27]'
)

SECRETS_FOUND=""
for pattern in "${SECRET_PATTERNS[@]}"; do
    MATCHES=$(echo "$FILES" | xargs grep -ilE "$pattern" 2>/dev/null || true)
    if [ -n "$MATCHES" ]; then
        SECRETS_FOUND="$SECRETS_FOUND$MATCHES"$'\n'
    fi
done

# Filter out false positives (env examples, tests, type definitions)
SECRETS_FOUND=$(echo "$SECRETS_FOUND" | grep -v '\.example\|\.test\.\|\.spec\.\|\.d\.ts$\|types\.ts$' | sort -u | grep -v '^$' || true)

if [ -n "$SECRETS_FOUND" ]; then
    print_error "Potential hardcoded secrets found:"
    echo "$SECRETS_FOUND" | head -5 | sed 's/^/    /'
    print_info "Use environment variables instead (process.env.VAR_NAME)"
    ERRORS=$((ERRORS + 1))
else
    print_success "No hardcoded secrets detected"
fi

echo ""

# =============================================================================
# Check 2: HTTP_STATUS constant usage (BLOCKS commit)
# =============================================================================
echo "Checking HTTP status code usage..."

# Find direct numeric status codes in API routes (should use HTTP_STATUS constants)
HTTP_STATUS_VIOLATIONS=""
API_ROUTES=$(echo "$FILES" | grep -E 'src/app/api/.*route\.ts$' || true)

if [ -n "$API_ROUTES" ]; then
    # Look for patterns like: status: 200, status: 404, { status: 500 }
    # Exclude comments and string literals
    HTTP_STATUS_VIOLATIONS=$(echo "$API_ROUTES" | xargs grep -nE '\bstatus:\s*(200|201|204|400|401|403|404|409|500|502|503)\b' 2>/dev/null | grep -v '//.*status:' | grep -v 'HTTP_STATUS' || true)
fi

if [ -n "$HTTP_STATUS_VIOLATIONS" ]; then
    print_error "Direct HTTP status codes found (use HTTP_STATUS constants):"
    echo "$HTTP_STATUS_VIOLATIONS" | head -5 | sed 's/^/    /'
    print_info "Import: import { HTTP_STATUS } from '@/lib/core/constants/http-status'"
    print_info "Usage: status: HTTP_STATUS.OK, HTTP_STATUS.NOT_FOUND, etc."
    ERRORS=$((ERRORS + 1))
else
    print_success "HTTP status codes properly use constants"
fi

echo ""

# =============================================================================
# Check 3: File size limit (BLOCKS commit if > 500 lines)
# =============================================================================
echo "Checking file sizes..."

MAX_LINES=500
LARGE_FILES=""

for file in $FILES; do
    if [ -f "$file" ]; then
        LINES=$(wc -l < "$file" | xargs)
        if [ "$LINES" -gt "$MAX_LINES" ]; then
            LARGE_FILES="$LARGE_FILES$file ($LINES lines)"$'\n'
        fi
    fi
done

LARGE_FILES=$(echo "$LARGE_FILES" | grep -v '^$' || true)

if [ -n "$LARGE_FILES" ]; then
    print_error "Files exceed $MAX_LINES line limit:"
    echo "$LARGE_FILES" | head -5 | sed 's/^/    /'
    print_info "Consider splitting into smaller modules"
    ERRORS=$((ERRORS + 1))
else
    print_success "All files within size limit ($MAX_LINES lines)"
fi

echo ""

# =============================================================================
# Check 4: Import alias enforcement (WARNS on relative imports)
# =============================================================================
echo "Checking import aliases..."

# Find deep relative imports (../../ or deeper) that should use @/
RELATIVE_IMPORT_VIOLATIONS=""
for file in $FILES; do
    if [ -f "$file" ]; then
        # Look for imports with 3+ levels of ../
        VIOLATIONS=$(grep -nE "from ['\"]\.\.\/\.\.\/" "$file" 2>/dev/null || true)
        if [ -n "$VIOLATIONS" ]; then
            RELATIVE_IMPORT_VIOLATIONS="$RELATIVE_IMPORT_VIOLATIONS$file:"$'\n'"$VIOLATIONS"$'\n'
        fi
    fi
done

RELATIVE_IMPORT_VIOLATIONS=$(echo "$RELATIVE_IMPORT_VIOLATIONS" | grep -v '^$' || true)

if [ -n "$RELATIVE_IMPORT_VIOLATIONS" ]; then
    print_warning "Deep relative imports found (prefer @/ alias):"
    echo "$RELATIVE_IMPORT_VIOLATIONS" | head -8 | sed 's/^/    /'
    print_info "Use: import { X } from '@/lib/module' instead of '../../../lib/module'"
    WARNINGS=$((WARNINGS + 1))
else
    print_success "Import aliases used correctly"
fi

echo ""

# =============================================================================
# Check 5: No TODO/FIXME in commits (WARNS)
# =============================================================================
echo "Checking for TODO/FIXME comments..."

TODO_VIOLATIONS=""
for file in $FILES; do
    if [ -f "$file" ]; then
        TODOS=$(grep -nE '(TODO|FIXME|XXX|HACK):?' "$file" 2>/dev/null | grep -v 'no-TODO-check' || true)
        if [ -n "$TODOS" ]; then
            TODO_VIOLATIONS="$TODO_VIOLATIONS$file:"$'\n'"$TODOS"$'\n'
        fi
    fi
done

TODO_VIOLATIONS=$(echo "$TODO_VIOLATIONS" | grep -v '^$' || true)

if [ -n "$TODO_VIOLATIONS" ]; then
    print_warning "TODO/FIXME comments found:"
    echo "$TODO_VIOLATIONS" | head -8 | sed 's/^/    /'
    print_info "Consider resolving or creating issues before committing"
    WARNINGS=$((WARNINGS + 1))
else
    print_success "No TODO/FIXME comments in staged files"
fi

echo ""

# =============================================================================
# Summary
# =============================================================================
echo "----------------------------------------"
if [ $ERRORS -gt 0 ]; then
    print_error "Code quality check failed with $ERRORS error(s), $WARNINGS warning(s)"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    print_warning "Code quality check passed with $WARNINGS warning(s)"
    exit 0
else
    print_success "All code quality checks passed!"
    exit 0
fi
