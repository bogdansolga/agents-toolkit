---
command: nextjs:audit
description: Audit a Next.js 16 project for performance, best practices, and optimization opportunities
---

## Description

Performs a comprehensive audit of a Next.js 16 project focusing on:
- Performance optimizations
- Caching strategy effectiveness
- Best practices compliance
- Bundle size analysis
- Security patterns
- Code quality specific to Next.js

## Parameters

- `path` (optional): Path to Next.js project. Defaults to current directory.
- `--focus` (optional): Focus area - `performance`, `caching`, `security`, `all` (default: `all`)
- `--json` (optional): Output in JSON format

## Execution Steps

### 1. Project Verification

```bash
# Verify Next.js 16 project
ls next.config.* 2>/dev/null || { echo "ERROR: Not a Next.js project"; exit 1; }

# Get versions
cat package.json | jq -r '{
  name: .name,
  next: .dependencies.next // .devDependencies.next,
  react: .dependencies.react
}'
```

### 2. Configuration Audit

#### 2.1 Check Recommended Settings

```bash
echo "=== Configuration Audit ==="

# React Compiler
grep -q "reactCompiler.*true" next.config.* && echo "✓ React Compiler enabled" || echo "✗ React Compiler not enabled"

# Cache Components
grep -q "cacheComponents.*true" next.config.* && echo "✓ cacheComponents enabled" || echo "✗ cacheComponents not enabled"

# Turbopack FS Cache
grep -q "turbopackFileSystemCacheForDev.*true" next.config.* && echo "✓ Turbopack FS cache enabled" || echo "○ Turbopack FS cache not enabled (optional)"

# Image optimization
grep -q "remotePatterns" next.config.* && echo "✓ Using remotePatterns for images" || echo "○ No remote image patterns configured"
```

#### 2.2 Check for Anti-Patterns

```bash
# force-dynamic overuse
FORCE_DYNAMIC=$(grep -rn "dynamic.*=.*force-dynamic" --include="*.ts" --include="*.tsx" app/ 2>/dev/null | wc -l)
[ "$FORCE_DYNAMIC" -gt 5 ] && echo "⚠ Found $FORCE_DYNAMIC force-dynamic exports - review if all are necessary"

# revalidate = 0 (disables caching)
REVALIDATE_ZERO=$(grep -rn "revalidate.*=.*0" --include="*.ts" --include="*.tsx" app/ 2>/dev/null | wc -l)
[ "$REVALIDATE_ZERO" -gt 0 ] && echo "⚠ Found $REVALIDATE_ZERO revalidate=0 - caching disabled"
```

### 3. Caching Strategy Audit

#### 3.1 "use cache" Usage

```bash
echo "=== Caching Audit ==="

# Count cache directive usage
USE_CACHE=$(grep -rn '"use cache"' --include="*.ts" --include="*.tsx" . 2>/dev/null | wc -l)
echo "Cache directives found: $USE_CACHE"

# List cached components/functions
grep -rn '"use cache"' --include="*.ts" --include="*.tsx" . 2>/dev/null | head -10
```

#### 3.2 Cache Invalidation Patterns

```bash
# revalidateTag usage
REVALIDATE_TAGS=$(grep -rn "revalidateTag" --include="*.ts" --include="*.tsx" . 2>/dev/null)
echo "revalidateTag calls:"
echo "$REVALIDATE_TAGS" | head -10

# updateTag usage (new in 16)
UPDATE_TAGS=$(grep -rn "updateTag" --include="*.ts" --include="*.tsx" . 2>/dev/null)
echo "updateTag calls:"
echo "$UPDATE_TAGS" | head -10

# Check for proper cache profiles
grep -rn "revalidateTag(" --include="*.ts" . 2>/dev/null | grep -v "revalidateTag([^,]*," && \
  echo "⚠ Found revalidateTag without cache profile"
```

#### 3.3 Caching Opportunities

```bash
# Find fetch calls without caching
grep -rn "fetch(" --include="*.ts" --include="*.tsx" app/ 2>/dev/null | \
  grep -v "cache\|revalidate\|next:" | head -10

# Find database calls that could be cached
grep -rn "db\.\|prisma\.\|drizzle" --include="*.ts" --include="*.tsx" app/ 2>/dev/null | \
  grep -v '"use cache"' | head -10
```

### 4. Performance Audit

#### 4.1 Bundle Analysis

```bash
echo "=== Performance Audit ==="

# Check for large dependencies
cat package.json | jq -r '.dependencies | keys[]' | while read dep; do
  SIZE=$(du -sh node_modules/$dep 2>/dev/null | cut -f1)
  [ -n "$SIZE" ] && echo "$SIZE $dep"
done | sort -hr | head -10

# Check for moment.js (should use date-fns or dayjs)
grep -q '"moment"' package.json && echo "⚠ moment.js found - consider date-fns or dayjs"

# Check for lodash (should use lodash-es or native)
grep -q '"lodash"' package.json && echo "⚠ lodash found - consider lodash-es or native methods"
```

#### 4.2 Image Optimization

```bash
# Find unoptimized images
echo "Unoptimized <img> tags:"
grep -rn "<img " --include="*.tsx" --include="*.jsx" app/ components/ 2>/dev/null | \
  grep -v "node_modules" | head -10

# Check next/image usage
NEXT_IMAGES=$(grep -rn "from ['\"]next/image['\"]" --include="*.tsx" . 2>/dev/null | wc -l)
echo "next/image imports: $NEXT_IMAGES"

# Check for missing priority on LCP images
grep -rn "<Image" --include="*.tsx" app/page.tsx app/*/page.tsx 2>/dev/null | \
  grep -v "priority" | head -5 && echo "⚠ Consider adding priority to above-fold images"
```

#### 4.3 Code Splitting

```bash
# Find large page components
for page in $(find app -name "page.tsx" 2>/dev/null); do
  LINES=$(wc -l < "$page")
  [ "$LINES" -gt 200 ] && echo "⚠ Large page: $page ($LINES lines) - consider splitting"
done

# Check dynamic imports usage
DYNAMIC_IMPORTS=$(grep -rn "dynamic(" --include="*.tsx" . 2>/dev/null | wc -l)
echo "Dynamic imports: $DYNAMIC_IMPORTS"
```

### 5. Server/Client Boundary Audit

```bash
echo "=== Component Boundary Audit ==="

# Count client components
CLIENT_COMPONENTS=$(grep -rl "'use client'" --include="*.tsx" . 2>/dev/null | wc -l)
echo "Client components: $CLIENT_COMPONENTS"

# Find client components that might not need to be
grep -rl "'use client'" --include="*.tsx" . 2>/dev/null | while read file; do
  # Check if it actually uses client features
  if ! grep -q "useState\|useEffect\|useContext\|onClick\|onChange\|onSubmit" "$file"; then
    echo "⚠ Possibly unnecessary 'use client': $file"
  fi
done | head -10

# Find server components doing client work
grep -rn "useState\|useEffect" --include="*.tsx" app/ 2>/dev/null | \
  while read line; do
    FILE=$(echo "$line" | cut -d: -f1)
    if ! grep -q "'use client'" "$FILE"; then
      echo "⚠ Client hook in server component: $line"
    fi
  done | head -10
```

### 6. Security Audit

```bash
echo "=== Security Audit ==="

# dangerouslySetInnerHTML usage
DANGEROUS=$(grep -rn "dangerouslySetInnerHTML" --include="*.tsx" . 2>/dev/null)
[ -n "$DANGEROUS" ] && echo "⚠ dangerouslySetInnerHTML found - ensure content is sanitized:" && echo "$DANGEROUS" | head -5

# Environment variable exposure
grep -rn "process.env" --include="*.tsx" app/ 2>/dev/null | \
  grep -v "NEXT_PUBLIC" | head -5 && echo "⚠ Non-public env vars in app/ - verify server-only"

# API route authentication
for route in $(find app/api -name "route.ts" 2>/dev/null); do
  if ! grep -q "auth\|session\|token\|middleware" "$route"; then
    echo "○ No obvious auth in: $route"
  fi
done | head -10
```

### 7. AI Documentation Check

```bash
echo "=== AI Documentation Audit ==="

if [ -f "AGENTS.md" ] && [ -d ".next-docs" ]; then
  echo "✓ AGENTS.md configured"
  echo "  Docs version: $(head -1 .next-docs/*.md 2>/dev/null | head -1)"
else
  echo "✗ AGENTS.md not configured"
  echo "  Quick setup: cp -r ~/.claude-config/next-docs ./.next-docs"
  echo "  Or run: bunx @next/codemod@canary agents-md"
  echo "  Benefit: 100% AI accuracy on framework tasks"
fi
```

### 8. Generate Report

```markdown
## Next.js 16 Audit Report

**Project:** {name}
**Version:** Next.js {version}
**Date:** {date}

---

### Configuration Score: {X}/10

| Setting | Status | Impact |
|---------|--------|--------|
| React Compiler | ✓/✗ | High - automatic memoization |
| cacheComponents | ✓/✗ | High - PPR support |
| Turbopack FS Cache | ✓/○ | Medium - faster dev |
| AGENTS.md | ✓/✗ | High - AI accuracy |

---

### Caching Analysis

**Current State:**
- Cache directives: {N}
- revalidateTag calls: {N}
- updateTag calls: {N}

**Opportunities:**
{list of uncached fetches/queries that could benefit}

**Recommendations:**
1. Add "use cache" to {specific components}
2. Consider caching {specific data fetches}

---

### Performance Analysis

**Bundle Concerns:**
{large dependencies}

**Image Optimization:**
- Using next/image: {N} components
- Unoptimized <img>: {N} instances

**Code Splitting:**
- Large pages needing split: {list}
- Dynamic imports: {N}

---

### Component Boundaries

- Client components: {N}
- Potentially unnecessary client components: {list}
- Server components with client code: {list}

---

### Security Notes

{findings}

---

### Quick Wins

1. {actionable item with expected benefit}
2. {actionable item with expected benefit}
3. {actionable item with expected benefit}

---

### Recommended Actions

**High Priority:**
- {action}

**Medium Priority:**
- {action}

**Low Priority:**
- {action}
```

### 9. Interactive Options

```
What would you like to do?

1. Fix configuration issues
2. Add caching to identified opportunities
3. Optimize images
4. Setup AGENTS.md
5. View detailed findings for specific area
6. Exit
```

## Success Criteria

- All audit checks complete
- Report generated with actionable items
- Quick wins identified
- No false positives

## Example Usage

```bash
# Full audit
/nextjs:audit

# Focus on performance
/nextjs:audit --focus=performance

# Focus on caching strategy
/nextjs:audit --focus=caching

# Audit specific project
/nextjs:audit /path/to/project
```
